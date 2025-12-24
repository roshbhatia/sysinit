local wezterm = require("wezterm")
local json_loader = require("sysinit.pkg.utils.json_loader")
local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"))

local M = {}

local font_name = theme_config.font and theme_config.font.monospace or "MonoLisa"

local function is_linux()
  local handle = io.popen("uname -s 2>/dev/null")
  if not handle then
    return false
  end
  local result = handle:read("*a")
  handle:close()
  return result:match("Linux") ~= nil
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

local function truncate(str, max_len)
  if #str <= max_len then
    return str
  end
  return str:sub(1, max_len - 1) .. "…"
end

local function get_tab_content(tab)
  local cwd_uri = tab.active_pane.current_working_dir
  if cwd_uri then
    local cwd_url = tostring(cwd_uri)
    local cwd_path = cwd_url:gsub("file://[^/]*/", "/")
    local basename = cwd_path:match("([^/]+)/?$")
    if basename and basename ~= "" then
      return basename
    end
  end

  local process = tab.active_pane.foreground_process_name
  if process then
    return process:match("([^/]+)$")
  end

  return "shell"
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

wezterm.on("format-tab-title", function(tab)
  local index = tab.tab_index + 1
  local content = truncate(get_tab_content(tab), 19)
  local bracket = tab.is_active and "[" or ""
  local bracket_close = tab.is_active and "]" or ""

  return {
    { Text = "  " },
    { Foreground = { Color = "#000000" } },
    { Text = bracket .. index .. ":" .. content .. bracket_close .. " " },
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
  overrides.colors.tab_bar = {
    background = mode_color,
    active_tab = {
      bg_color = mode_color,
      fg_color = "#000000",
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = mode_color,
      fg_color = "#000000",
    },
    inactive_tab_hover = {
      bg_color = mode_color,
      fg_color = "#000000",
    },
  }
  window:set_config_overrides(overrides)

  window:set_left_status("")
  window:set_right_status(wezterm.format({
    { Foreground = { Color = "#000000" } },
    { Text = padding .. mode_text .. "  " },
  }))
end)

local function get_window_appearance_config()
  local config = {
    window_padding = {
      left = "1cell",
      right = "1cell",
      top = "1cell",
    },
  }

  if is_linux() then
    config.window_decorations = "RESIZE"
    config.enable_wayland = true
  end

  return config
end

local function get_display_config()
  return {
    window_decorations = "RESIZE",
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
  }
end

local function get_visual_bell_config()
  return {
    fade_in_function = "EaseIn",
    fade_in_duration_ms = 70,
    fade_out_function = "EaseOut",
    fade_out_duration_ms = 100,
  }
end

local function get_font_config()
  return {
    font = terminal_font,
    font_size = 13.0,
  }
end

local function get_tab_bar_colors()
  return {
    active_tab = {
      fg_color = "#000000",
      intensity = "Bold",
    },
    inactive_tab = {
      fg_color = "#000000",
    },
    inactive_tab_hover = {
      fg_color = "#000000",
    },
  }
end

function M.setup(config)
  for _, cfg in ipairs({
    get_window_appearance_config(),
    get_display_config(),
    get_font_config(),
  }) do
    for key, value in pairs(cfg) do
      config[key] = value
    end
  end

  config.visual_bell = get_visual_bell_config()
  config.colors = config.colors or {}
  config.colors.tab_bar = get_tab_bar_colors()

  config.mouse_bindings = config.mouse_bindings or {}
  table.insert(config.mouse_bindings, {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = wezterm.action.CloseCurrentTab({ confirm = false }),
  })
end

return M
