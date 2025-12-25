local wezterm = require("wezterm")
local json_loader = require("sysinit.pkg.utils.json_loader")

local M = {}

local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"))
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
  config.font = terminal_font
  config.font_size = 13.0

  config.window_decorations = "RESIZE"
  config.window_padding = {
    left = "1cell",
    right = "1cell",
    top = "1cell",
  }

  if is_linux() then
    config.enable_wayland = true
  end

  config.window_frame = { font = terminal_font }
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

  local transparency = true
  ---@diagnostic disable-next-line: undefined-field
  local opacity = transparency.opacity or 0.85
  ---@diagnostic disable-next-line: undefined-field
  local blur = transparency.blur or 80
  local theme_name = theme_config.theme_name

  config.macos_window_background_blur = blur
  config.window_background_opacity = opacity
  config.color_scheme = theme_name

  local bar = wezterm.plugin.require("https://github.com/hikarisakamoto/bar.wezterm")
  bar.apply_to_config(config, {
    modules = {
      clock = {
        enabled = false,
      },
    },
  })
end

return M
