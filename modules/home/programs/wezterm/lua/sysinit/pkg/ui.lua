local wezterm = require("wezterm")

local keybindings = require("sysinit.pkg.keybindings")
local utils = require("sysinit.pkg.utils")

local M = {}

function M.setup(config)
  local config_data = utils.load_json_file(utils.get_config_path("config.json"))
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

  -- Core settings
  config.font = font
  config.font_size = 11.0
  config.line_height = 1.0
  config.cell_width = 1.0
  -- color_scheme is set by Stylix via home-manager
  config.animation_fps = 240
  config.max_fps = 240
  config.cursor_blink_rate = 320
  config.cursor_thickness = 1
  config.scrollback_lines = 200000
  config.quick_select_alphabet = "fjdkslaghrueiwoncmv"
  config.adjust_window_size_when_changing_font_size = false
  config.use_resize_increments = false
  config.pane_focus_follows_mouse = false

  config.tab_bar_at_bottom = true
  config.use_fancy_tab_bar = false
  config.hide_tab_bar_if_only_one_tab = false

  config.window_frame = {
    font = font,
    font_size = 11.0,
  }

  config.visual_bell = {
    fade_in_function = "EaseIn",
    fade_in_duration_ms = 70,
    fade_out_function = "EaseOut",
    fade_out_duration_ms = 100,
  }

  config.window_background_opacity = config_data.transparency.opacity

  if utils.is_darwin() then
    -- macOS: compositor handles blur, wezterm handles opacity
    config.front_end = "WebGpu"
    config.window_decorations = "RESIZE|MACOS_FORCE_ENABLE_SHADOW"
    config.macos_window_background_blur = config_data.transparency.blur
  else
    -- Linux/Wayland (sway)
    config.enable_wayland = false
    config.front_end = "WebGpu"
    config.window_decorations = "RESIZE"
    config.freetype_load_flags = "NO_HINTING|NO_AUTOHINT"
    -- Tell wezterm it's in a tiling WM so it accounts for
    -- window sizing correctly (fixes tab bar cutoff)
    config.tiling_desktop_environments = {
      "X11 LG3D",
      "X11 bspwm",
      "X11 i3",
      "X11 dwm",
      "Wayland",
    }
  end

  local function locked_indicator()
    if keybindings.locked_mode then
      return "  "
    end
    return "  "
  end

  local tabline_ok, tabline = pcall(wezterm.plugin.require, "https://github.com/michaelbrusegard/tabline.wez")
  if not tabline_ok then
    wezterm.log_warn("Failed to load tabline.wez: " .. tostring(tabline))
  end
  if tabline_ok then
    tabline.setup({
      options = {
        section_separators = {
          left = "",
          right = "",
        },
        component_separators = {
          left = "",
          right = "",
        },
        tab_separators = {
          left = "",
          right = "",
        },
      },
      sections = {
        tabline_a = {
          "mode",
          locked_indicator,
        },
        tabline_x = {},
        tabline_y = {},
      },
      extensions = {},
    })
    tabline.apply_to_config(config)
  end

  -- Fallback: if tabline plugin didn't load, use native right_status for locked indicator
  if not tabline_ok then
    wezterm.on("update-right-status", function(window, _pane)
      local mode_text = locked_indicator()
      window:set_right_status(wezterm.format({
        { Text = mode_text },
      }))
    end)
  end

  -- Post-process window padding for macOS
  if utils.is_darwin() then
    -- Set window padding AFTER tabline.apply_to_config, which zeroes all padding
    config.window_padding = {
      left = "1cell",
      right = "1cell",
      top = "1cell",
      bottom = "0cell",
    }
  end

  local agent_deck_ok, agent_deck = pcall(wezterm.plugin.require, "https://github.com/Eric162/wezterm-agent-deck")
  if not agent_deck_ok then
    wezterm.log_warn("Failed to load agent-deck: " .. tostring(agent_deck))
  end
  if agent_deck_ok then
    agent_deck.apply_to_config(config, {
      tab_title = { enabled = false },
      right_status = { enabled = false },
      cooldown_ms = 1500,
      max_lines = 500,
      notifications = {
        enabled = true,
        on_waiting = true,
        backend = "native",
      },
      agents = {
        claude = {
          patterns = { "claude", "claude%-code" },
          executable_patterns = { "@anthropic%-ai/claude%-code", "/claude%-code/", "/claude$" },
          argv_patterns = { "@anthropic%-ai/claude%-code", "claude%-code", "^claude%s*$" },
          title_patterns = { "claude code", "claude" },
        },
        goose = {
          patterns = { "goose", "goosed" },
          executable_patterns = { "/goose$", "/goosed$" },
          argv_patterns = { "^goose%s*$" },
          title_patterns = { "goose" },
        },
        amp = {
          patterns = { "amp" },
          executable_patterns = { "/amp$" },
          argv_patterns = { "^amp%s*$" },
          title_patterns = { "amp" },
        },
        copilot = {
          patterns = { "copilot" },
          executable_patterns = { "/copilot$", "copilot%-language%-server" },
          argv_patterns = { "^copilot%s*$" },
          title_patterns = { "copilot" },
        },
        cursor = {
          patterns = { "cursor%-agent", "cursor" },
          executable_patterns = { "/cursor%-agent$" },
          argv_patterns = { "cursor%-agent" },
          title_patterns = { "cursor" },
        },
        crush = {
          patterns = { "crush" },
          executable_patterns = { "/crush$" },
          argv_patterns = { "^crush%s*$" },
          title_patterns = { "crush" },
        },
        aider = {
          patterns = { "aider" },
          executable_patterns = { "/aider$" },
          argv_patterns = { "^aider%s*$" },
          title_patterns = { "aider" },
        },
        opencode = {
          patterns = { "opencode" },
          executable_patterns = { "opencode%-darwin", "opencode%-linux", "/opencode$" },
          argv_patterns = { "bunx%s+opencode", "npx%s+opencode", "/opencode$" },
          title_patterns = { "opencode" },
        },
      },
    })
  end

  config.hyperlink_rules = wezterm.default_hyperlink_rules()
end

return M
