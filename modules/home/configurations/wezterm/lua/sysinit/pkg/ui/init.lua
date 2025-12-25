local wezterm = require("wezterm")
local platform = require("sysinit.pkg.utils.platform")
local json_loader = require("sysinit.pkg.utils.json_loader")

local bar = wezterm.plugin.require("https://github.com/hikarisakamoto/bar.wezterm")

local M = {}

function M.setup(config)
  local config_data = json_loader.load_json_file(json_loader.get_config_path("config.json"))
  local font = wezterm.font_with_fallback({
    {
      family = config_data.font.monospace,
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
    config_data.font.symbols,
  })

  config.adjust_window_size_when_changing_font_size = not platform.is_darwin()
  config.animation_fps = 240
  config.color_scheme = config_data.color_scheme
  config.cursor_blink_ease_in = "EaseIn"
  config.cursor_blink_ease_out = "EaseInOut"
  config.cursor_blink_rate = 225
  config.cursor_thickness = 1
  config.display_pixel_geometry = "BGR"
  config.dpi = 144
  config.enable_scroll_bar = true
  config.enable_tab_bar = true
  config.enable_wayland = platform.is_linux()
  config.font = font
  config.font_size = 13.0
  config.macos_window_background_blur = platform.is_darwin() and config_data.transparency.blur or 0
  config.max_fps = 240
  config.quick_select_alphabet = "fjdkslaghrueiwoncmv"
  config.scrollback_lines = 20000
  config.text_min_contrast_ratio = 4.5
  config.window_background_opacity = config_data.transparency.opacity
  config.window_decorations = platform.is_darwin() and "RESIZE|MACOS_FORCE_ENABLE_SHADOW"
    or "RESIZE"
  config.window_frame = {
    font = font,
    font_size = 13.0,
  }
  config.window_padding = {
    left = "1cell",
    right = "1cell",
    top = "1cell",
  }
  config.visual_bell = {
    fade_in_function = "EaseIn",
    fade_in_duration_ms = 70,
    fade_out_function = "EaseOut",
    fade_out_duration_ms = 100,
  }

  bar.apply_to_config(config, {
    padding = {
      tabs = {
        left = 1,
      },
    },
    modules = {
      clock = {
        enabled = false,
      },
      leader = {
        enabled = false,
      },
      username = {
        enabled = false,
      },
      workspace = {
        enabled = false,
      },
    },
  })
end

return M
