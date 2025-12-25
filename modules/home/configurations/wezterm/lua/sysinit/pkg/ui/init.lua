local wezterm = require("wezterm")
local json_loader = require("sysinit.pkg.utils.json_loader")
local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"))

local bar = wezterm.plugin.require("https://github.com/hikarisakamoto/bar.wezterm")

local M = {}

local function is_linux()
  local handle = io.popen("uname -s 2>/dev/null")
  if not handle then
    return false
  end
  local result = handle:read("*a")
  handle:close()
  return result:match("Linux") ~= nil
end

function M.setup(config)
  local font = wezterm.font_with_fallback({
    {
      family = theme_config.font.monospace,
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
    theme_config.font.nerdfontFallback,
  })

  config.font = font
  config.font_size = 13.0
  config.window_frame = { font = font }

  config.window_decorations = "RESIZE"
  config.window_padding = {
    left = "1cell",
    right = "1cell",
    top = "1cell",
  }

  if is_linux() then
    config.enable_wayland = true
  end

  config.adjust_window_size_when_changing_font_size = false
  config.animation_fps = 240
  config.cursor_blink_ease_in = "EaseIn"
  config.cursor_blink_ease_out = "EaseInOut"
  config.cursor_blink_rate = 600
  config.cursor_thickness = 1
  config.display_pixel_geometry = "BGR"
  config.dpi = 144
  config.enable_scroll_bar = false
  config.enable_tab_bar = true
  config.max_fps = 240
  config.quick_select_alphabet = "fjdkslaghrueiwoncmv"
  config.scrollback_lines = 20000
  config.text_min_contrast_ratio = 4.5
  config.visual_bell = {
    fade_in_function = "EaseIn",
    fade_in_duration_ms = 70,
    fade_out_function = "EaseOut",
    fade_out_duration_ms = 100,
  }

  config.color_scheme = theme_config.theme_name
  config.macos_window_background_blur = theme_config.transparency.blur
  config.window_background_opacity = theme_config.transparency.opacity

  bar.apply_to_config(config, {
    modules = {
      clock = {
        enabled = false,
      },
    },
  })
end

return M
