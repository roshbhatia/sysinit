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

  config.font = font
  config.font_size = 13.0
  config.window_frame = { font = font }

  config.window_decorations = "RESIZE"
  config.window_padding = {
    left = "1cell",
    right = "1cell",
    top = "1cell",
  }

  config.animation_fps = 240
  config.cursor_blink_ease_in = "EaseIn"
  config.cursor_blink_ease_out = "EaseInOut"
  config.cursor_blink_rate = 600
  config.cursor_thickness = 1
  config.display_pixel_geometry = "BGR"
  config.dpi = 144
  config.enable_scroll_bar = true
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

  config.color_scheme = config_data.color_scheme
  config.window_background_opacity = config_data.transparency.opacity

  if platform.is_linux() then
    config.enable_wayland = true
  end

  if platform.is_macos() then
    config.adjust_window_size_when_changing_font_size = false
    if config_data.transparency.blur then
      config.macos_window_background_blur = config_data.transparency.blur
    end
  end

  bar.apply_to_config(config, {
    padding = {
      left = 2,
      right = 2,
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
