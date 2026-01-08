local wezterm = require("wezterm")
local platform = require("sysinit.pkg.utils.platform")
local json_loader = require("sysinit.pkg.utils.json_loader")
local uri_handler = require("sysinit.pkg.utils.uri_handler")

local bar = wezterm.plugin.require("https://github.com/hikarisakamoto/bar.wezterm")

local M = {}

local function should_be_opaque(tab)
  for _, pane in ipairs(tab:panes()) do
    local info = pane:get_foreground_process_info()
    if info then
      local executable = string.gsub(info.executable, "(.*[/\\])(.*)", "%2")
      if executable == "nvim" or executable == "tmux" or executable == "hx" then
        return true
      end
    end
  end
  return false
end

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
        "zero",
      },
    },
    config_data.font.symbols,
  })

  config.adjust_window_size_when_changing_font_size = not platform.is_darwin()
  config.animation_fps = 60
  config.color_scheme = config_data.color_scheme
  config.cursor_blink_rate = 320
  config.cursor_thickness = 1
  config.dpi = 144
  config.font = font
  config.font_size = 13.0
  config.macos_window_background_blur = platform.is_darwin() and config_data.transparency.blur or 0
  config.max_fps = 240
  config.quick_select_alphabet = "fjdkslaghrueiwoncmv"
  config.scrollback_lines = 20000
  config.text_min_contrast_ratio = 4.5
  config.window_background_opacity = config_data.transparency.opacity
  config.window_decorations = platform.is_darwin() and "RESIZE|MACOS_FORCE_ENABLE_SHADOW" or "RESIZE"
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

  -- Configure hyperlink rules for file paths and URIs
  config.hyperlink_rules = {
    -- URL with a protocol
    {
      regex = "\\b\\w+://(?:[\\w.-]+)\\.[a-z]{2,15}\\S*\\b",
      format = "$0",
    },

    -- implicit mailto link
    {
      regex = "\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b",
      format = "mailto:$0",
    },

    -- file:// URIs
    {
      regex = "\\bfile://\\S*\\b",
      format = "$0",
    },

    -- Absolute paths (starting with /)
    {
      regex = "\\b/[^\\s]*\\b",
      format = "$EDITOR:$0",
    },

    -- Relative paths with ./ or ../
    {
      regex = "\\b\\.{1,2}/[^\\s]*\\b",
      format = "$EDITOR:$0",
    },

    -- Catch-all for other whitespace-delimited sequences
    -- (including filenames without path separators)
    {
      regex = "\\b\\S+\\b",
      format = "$EDITOR:$0",
    },
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

  -- Setup URI handler for file editing and previewing
  uri_handler.setup(config)

  wezterm.on("update-status", function(window, pane)
    local tab = pane:tab()
    local should_switch = should_be_opaque(tab)
    local overrides = window:get_config_overrides() or {}
    if should_switch then
      overrides.window_background_opacity = 1.0
    else
      overrides.window_background_opacity = nil
    end
    window:set_config_overrides(overrides)
  end)
end

return M
