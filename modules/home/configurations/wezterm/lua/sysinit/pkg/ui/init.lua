local wezterm = require("wezterm")
local json_loader = require("sysinit.pkg.utils.json_loader")
local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"))
local M = {}

local font_name = theme_config.font and theme_config.font.monospace
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

local function basename(path)
  if not path or path == "" then
    return ""
  end
  path = path:gsub("[\\/]+$", "")
  local name = path:match("[\\/]?([^%\\/]+)$")
  return name or ""
end

local function parent_basename(path)
  if not path or path == "" then
    return ""
  end
  path = path:gsub("[\\/]+$", "")
  local parent_path = path:match("^(.*)[\\/][^\\/]*$")
  if not parent_path or parent_path == "" then
    return ""
  end
  local name = parent_path:match("[\\/]?([^%\\/]+)$")
  return name or ""
end

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
  if not proc then
    return false
  end
  local name = basename(proc)
  return name:match("^n?vim$") or name:match("^n?vim%.")
end

local function get_effective_transparency()
  if theme_config.nvim_transparency_override and is_nvim_running() then
    return theme_config.nvim_transparency_override
  end
  return theme_config.transparency
end

local function apply_transparency_overrides(overrides)
  local transparency = get_effective_transparency()
  local opacity = transparency.opacity or 0.85
  local blur = transparency.blur or 80
  if overrides.window_background_opacity ~= opacity then
    overrides.window_background_opacity = opacity
    overrides.macos_window_background_blur = blur
  end
end

local function truncate_component(str, max_len)
  str = tostring(str or "")
  local len = #str
  if len <= max_len then
    return str
  end

  local ellipsis = "…"
  local ellipsis_len = #ellipsis

  local available_for_parts = max_len - ellipsis_len
  if available_for_parts < 2 then
    return str:sub(1, max_len)
  end

  local left_len = math.floor(available_for_parts / 2)
  local right_len = available_for_parts - left_len

  local left = str:sub(1, left_len)
  local right = str:sub(-right_len)

  return left .. ellipsis .. right
end

local function get_tab_content(tab, max_width)
  local pane_info = tab.active_pane

  local pane = wezterm.mux.get_pane(pane_info.pane_id)
  local domain = wezterm.mux.get_domain(pane:get_domain_name()):name()

  local path = (pane_info.current_working_dir and pane_info.current_working_dir)
    or (pane and pane:get_current_working_dir().file_path)
    or ""

  local process = basename(pane.foreground_process_name)

  local components = {}

  if domain ~= "" and domain ~= "local" then
    table.insert(components, "<" .. domain .. ">")
  end

  local show_dir = path ~= ""
    and (
      process == "git"
      or process == "hx"
      or process == "task"
      or process == "wezterm-gui"
      or process:match("^n?vim$")
      or process:match("^n?vim%.")
      or process == "zsh"
    )

  if show_dir then
    local parent_name = parent_basename(path)
    local current_name = basename(path)
    local dir_part = current_name or ""
    if parent_name ~= "" and parent_name ~= "/" then
      dir_part = parent_name .. "/" .. dir_part
    end
    if dir_part ~= "" then
      table.insert(components, dir_part)
    end
  else
    if process ~= "" then
      table.insert(components, process)
    end
  end

  local num = #components
  if num == 0 then
    return ""
  end

  local separator = "|"
  local separator_cost = (num - 1) * #separator

  local available = max_width - separator_cost
  if available <= 0 then
    return string.rep(" ", max_width) -- shouldn't happen, but safe
  end

  if num == 1 then
    return truncate_component(components[1], available)
  end

  local first_max = math.max(10, math.floor(available * 0.55)) -- at least 10, up to ~55%
  local remaining_after_first = available - first_max

  local rest_num = num - 1
  local per_rest = rest_num > 0 and math.floor(remaining_after_first / rest_num) or 0
  local extra = rest_num > 0 and (remaining_after_first - per_rest * rest_num) or 0

  local lengths = {}
  table.insert(lengths, first_max)

  for i = 1, rest_num do
    local len = per_rest
    if i <= extra then
      len = len + 1
    end
    table.insert(lengths, len)
  end

  for i, comp in ipairs(components) do
    components[i] = truncate_component(comp, math.max(1, lengths[i]))
  end

  return table.concat(components, separator)
end

local function get_mode(window)
  local mode = window:active_key_table()
  return mode and mode ~= "" and mode or "default"
end

local function get_mode_name(mode)
  if mode == "default" then
    return "INSERT"
  end
  if mode:lower():find("copy") then
    return "NORMAL"
  end
  return mode:upper()
end

local function get_mode_color(mode)
  local p = theme_config.palette
  local lower = mode:lower()
  if lower:find("copy") then
    return p.error
  elseif lower:find("search") then
    return p.warning
  elseif lower:find("window") then
    return p.primary
  else
    return p.info
  end
end

---@diagnostic disable-next-line: unused-local
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local index = tab.tab_index + 1
  local content = get_tab_content(tab, max_width - 4)

  return {
    {
      Foreground = { Color = "#000000" },
    },
    {
      Attribute = {
        Underline = hover and "Single" or "None",
      },
    },
    {
      Text = " " .. index .. ": " .. content .. " ",
    },
  }
end)

wezterm.on("update-status", function(window, pane)
  local mode = get_mode(window)
  local mode_name = get_mode_name(mode)
  local mode_color = get_mode_color(mode)
  local dims = pane:get_dimensions()
  local mode_text = " " .. mode_name .. " "
  local padding = string.rep(" ", math.max(0, dims.cols - wezterm.column_width(mode_text) - 2))
  local overrides = window:get_config_overrides() or {}
  overrides.colors = overrides.colors or {}
  overrides.colors.tab_bar = overrides.colors.tab_bar or {}
  overrides.colors.tab_bar.background = mode_color
  overrides.colors.tab_bar.active_tab =
    { bg_color = mode_color, fg_color = "#000000", intensity = "Bold" }
  overrides.colors.tab_bar.inactive_tab = { bg_color = mode_color, fg_color = "#000000" }
  overrides.colors.tab_bar.inactive_tab_hover = { bg_color = mode_color, fg_color = "#000000" }
  if theme_config.nvim_transparency_override then
    apply_transparency_overrides(overrides)
  end
  window:set_config_overrides(overrides)
  window:set_left_status("")
  window:set_right_status(wezterm.format({
    { Foreground = { Color = "#000000" } },
    { Attribute = { Intensity = "Bold" } },
    { Text = padding .. mode_text .. " " },
  }))
end)

local function get_base_config()
  local transparency = get_effective_transparency()
  local opacity = transparency.opacity or 0.85
  local blur = transparency.blur or 80
  return {
    macos_window_background_blur = blur,
    window_background_opacity = opacity,
    color_scheme = theme_config.theme_name,
    window_decorations = "RESIZE",
    window_padding = { left = "1cell", right = "1cell", top = "1cell" },
    enable_wayland = is_linux(),
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
    font = terminal_font,
    font_size = 13.0,
  }
end

function M.setup(config)
  local base = get_base_config()
  for k, v in pairs(base) do
    config[k] = v
  end
  if theme_config.nvim_transparency_override then
    wezterm.on("window-config-reloaded", function(window)
      local overrides = window:get_config_overrides() or {}
      apply_transparency_overrides(overrides)
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
