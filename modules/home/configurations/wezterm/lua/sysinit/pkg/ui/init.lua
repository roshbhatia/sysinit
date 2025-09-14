local wezterm = require("wezterm")
local M = {}

local terminal_font = wezterm.font_with_fallback({
  {
    family = "TX-02",
    harfbuzz_features = {
      "calt",
      "dlig",
      "liga",
      "salt",
      "ss01",
      "zero",
    },
  },
  {
    family = "JetBrains Mono",
    harfbuzz_features = {
      "calt",
      "dlig",
      "liga",
      "salt",
      "ss01",
      "zero",
    },
  },
  "Symbols Nerd Font",
})

local function get_window_appearance_config()
  return {
    window_padding = {
      left = "1cell",
      right = "1cell",
      top = "1cell",
    },
  }
end

local function get_display_config()
  return {
    window_frame = {
      font = terminal_font,
    },
    enable_tab_bar = false,
    window_decorations = "RESIZE",
    max_fps = 240,
    animation_fps = 240,
    scrollback_lines = 20000,
    adjust_window_size_when_changing_font_size = false,
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
    font_size = 14.0,
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
