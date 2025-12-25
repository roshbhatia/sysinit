local wezterm = require("wezterm")
local json_loader = require("sysinit.pkg.utils.json_loader")
local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"))

local M = {}

local font_name = theme_config.font and theme_config.font.monospace

local function is_linux()
  local handle = io.popen("uname -s 2>/dev/null")
  if not handle then
    return false
  end
  local result = handle:read("*a")
  handle:close()
  return result:match("Linux") ~= nil
end

local function is_nvim_running()
  local pane = wezterm.mux.get_active_pane()
  if not pane then
    return false
  end

  local proc = pane:get_foreground_process_name()
  if proc then
    local basename = proc:match("([^/]+)$")
    if basename and (basename:match("^n?vim$") or basename:match("^n?vim%.")) then
      return true
    end
  end
  return false
end

local function get_effective_transparency()
  if theme_config.nvim_transparency_override and is_nvim_running() then
    return theme_config.nvim_transparency_override
  end
  return theme_config.transparency
end

local terminal_font = wezterm.font_with_fallback({
  {
    family = font_name,
    harfbuzz_features = {
      "calt",
      "liga",
      "ss01",
      "ss02",
      "ss03",
      "ss04",
      "ss05",
      "ss06",
      "ss07",
      "ss08",
      "ss09",
      "ss10",
    },
  },
  "Symbols Nerd Font Mono",
})

local function truncate_component(str, max_len)
  str = tostring(str or "")
  if #str <= max_len then
    return str
  end
  return str:sub(1, max_len - 1) .. "…"
end

local function get_tab_content(tab)
  local hostname = ""
  local process_name = ""
  local path_display = ""

  local pane_info = tab.active_pane
  if not pane_info then
    return "shell"
  end

  local pane = wezterm.mux.get_pane(pane_info.pane_id)
  path_display = pane:get_current_working_dir() or ""
  process_name = string.gsub(pane:get_foreground_process_name(), "(.*[/\\])(.*)", "%2")
  hostname = pane:get_domain_name() or ""

  -- Build components list
  local components = {}
  if hostname ~= "" then
    table.insert(components, hostname)
  end
  if process_name ~= "" then
    table.insert(components, process_name)
  end
  if path_display ~= "" then
    table.insert(components, path_display)
  else
    table.insert(components, "shell")
  end

  -- Build final display with component truncation
  -- Allocate character budget: 19 chars max
  local max_total = 19
  local num_components = #components
  local separator_width = math.max(0, (num_components - 1) * 1)

  -- Distribute character budget among components
  local available = max_total - separator_width
  local per_component = math.floor(available / num_components)

  for i, comp in ipairs(components) do
    local max_len = per_component
    -- Give remaining chars to last component
    if i == num_components then
      max_len = available - (per_component * (num_components - 1))
    end
    components[i] = truncate_component(comp, math.max(1, max_len))
  end

  return table.concat(components, "|")
end

local function get_mode(window)
  local mode = window:active_key_table()
  return mode and mode ~= "" and mode or "default"
end

local function get_mode_name(mode)
  if mode == "default" then
    return "INSERT"
  elseif mode:lower():find("copy") then
    return "NORMAL"
  end
  return mode:upper()
end

local function get_mode_color(mode)
  local p = theme_config.palette
  local mode_lower = mode:lower()

  if mode_lower:find("copy") then
    return p.error
  elseif mode_lower:find("search") then
    return p.warning
  elseif mode_lower:find("window") then
    return p.primary
  end
  return p.info
end

---@diagnostic disable-next-line: unused-local
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local p = theme_config.palette
  local index = tab.tab_index + 1
  local content = get_tab_content(tab)
  local bracket = tab.is_active and "[" or ""
  local bracket_close = tab.is_active and "]" or ""

  return {
    { Text = "  " },
    { Foreground = { Color = p.fg_primary } },
    {
      Text = bracket .. index .. ":" .. content .. bracket_close .. " ",
    },
  }
end)

wezterm.on("update-status", function(window, pane)
  local mode = get_mode(window)
  local mode_name = get_mode_name(mode)
  local mode_color = get_mode_color(mode)

  local dims = pane:get_dimensions()
  local mode_text = "[" .. mode_name .. "]"
  local padding = string.rep(" ", math.max(0, dims.cols - wezterm.column_width(mode_text) - 2))

  local overrides = window:get_config_overrides() or {}
  overrides.colors = overrides.colors or {}
  overrides.colors.tab_bar = overrides.colors.tab_bar or {}
  overrides.colors.tab_bar.background = mode_color
  overrides.colors.tab_bar.active_tab = {
    bg_color = mode_color,
    fg_color = "#000000",
    intensity = "Bold",
  }
  overrides.colors.tab_bar.inactive_tab = {
    bg_color = mode_color,
    fg_color = "#000000",
  }
  overrides.colors.tab_bar.inactive_tab_hover = {
    bg_color = mode_color,
    fg_color = "#000000",
  }

  if theme_config.nvim_transparency_override then
    local transparency = get_effective_transparency()
    local new_opacity = transparency.opacity or 0.85
    local new_blur = transparency.blur or 80

    if overrides.window_background_opacity ~= new_opacity then
      overrides.window_background_opacity = new_opacity
      overrides.macos_window_background_blur = new_blur
    end
  end

  window:set_config_overrides(overrides)

  window:set_left_status("")
  window:set_right_status(wezterm.format({
    { Foreground = { Color = "#000000" } },
    { Attribute = { Intensity = "Bold" } },
    { Text = padding .. mode_text .. "  " },
  }))
end)

local function get_theme_colors()
  local transparency = get_effective_transparency()
  local opacity = transparency.opacity or 0.85
  local blur = transparency.blur or 80
  local theme_name = theme_config.theme_name

  return {
    macos_window_background_blur = blur,
    window_background_opacity = opacity,
    color_scheme = theme_name,
    colors = {
      foreground = theme_config.palette.fg_primary,
      background = theme_config.palette.bg_primary,
      cursor_bg = theme_config.palette.primary,
      cursor_fg = theme_config.palette.bg_primary,
      cursor_border = theme_config.palette.primary,
      selection_fg = theme_config.palette.bg_primary,
      selection_bg = theme_config.palette.primary,
      scrollbar_thumb = theme_config.palette.bg_overlay,
      split = theme_config.palette.bg_overlay,
      ansi = {
        theme_config.ansi["0"],
        theme_config.ansi["1"],
        theme_config.ansi["2"],
        theme_config.ansi["3"],
        theme_config.ansi["4"],
        theme_config.ansi["5"],
        theme_config.ansi["6"],
        theme_config.ansi["7"],
      },
      brights = {
        theme_config.ansi["8"],
        theme_config.ansi["9"],
        theme_config.ansi["10"],
        theme_config.ansi["11"],
        theme_config.ansi["12"],
        theme_config.ansi["13"],
        theme_config.ansi["14"],
        theme_config.ansi["15"],
      },
      tab_bar = {
        background = theme_config.palette.primary,
        active_tab = {
          bg_color = theme_config.palette.primary,
          fg_color = "#000000",
          intensity = "Bold",
        },
        inactive_tab = {
          bg_color = theme_config.palette.primary,
          fg_color = "#000000",
        },
        inactive_tab_hover = {
          bg_color = theme_config.palette.primary,
          fg_color = "#000000",
        },
      },
    },
  }
end

local function get_window_config()
  local config = {
    window_decorations = "RESIZE",
    window_padding = {
      left = "1cell",
      right = "1cell",
      top = "1cell",
    },
  }

  if is_linux() then
    config.enable_wayland = true
  end

  return config
end

local function get_display_config()
  return {
    window_frame = { font = terminal_font },
    adjust_window_size_when_changing_font_size = false,
    animation_fps = 240,
    cursor_blink_ease_in = "EaseIn",
    cursor_blink_ease_out = "EaseInOut",
    cursor_blink_rate = 600,
    cursor_thickness = 1,
    display_pixel_geometry = "BGR",
    dpi = 144,
    enable_scroll_bar = false,
    enable_tab_bar = true,
    max_fps = 240,
    quick_select_alphabet = "fjdkslaghrueiwoncmv",
    scrollback_lines = 20000,
    tab_bar_at_bottom = true,
    text_min_contrast_ratio = 4.5,
    use_fancy_tab_bar = false,
    show_new_tab_button_in_tab_bar = false,
    tab_max_width = 24,
    status_update_interval = 1000,
    visual_bell = {
      fade_in_function = "EaseIn",
      fade_in_duration_ms = 70,
      fade_out_function = "EaseOut",
      fade_out_duration_ms = 100,
    },
  }
end

local function get_font_config()
  return {
    font = terminal_font,
    font_size = 13.0,
  }
end

function M.setup(config)
  for _, cfg in ipairs({
    get_theme_colors(),
    get_window_config(),
    get_display_config(),
    get_font_config(),
  }) do
    for key, value in pairs(cfg) do
      config[key] = value
    end
  end

  if theme_config.nvim_transparency_override then
    wezterm.on("window-config-reloaded", function(window)
      local overrides = window:get_config_overrides() or {}
      local transparency = get_effective_transparency()

      overrides.window_background_opacity = transparency.opacity or 0.85
      overrides.macos_window_background_blur = transparency.blur or 80

      window:set_config_overrides(overrides)
    end)
  end

  config.mouse_bindings = config.mouse_bindings or {}
  table.insert(config.mouse_bindings, {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = wezterm.action.CloseCurrentTab({ confirm = false }),
  })
end

return M
