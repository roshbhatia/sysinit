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
    window_frame = {
      font = terminal_font,
    },
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

function M.setup(config)
  local configs = {
    get_window_appearance_config(),
    get_display_config(),
    get_font_config(),
  }

  for _, cfg in ipairs(configs) do
    for key, value in pairs(cfg) do
      config[key] = value
    end
  end

  config.visual_bell = get_visual_bell_config()
end

return M
