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

  config.adjust_window_size_when_changing_font_size = not utils.is_darwin()
  config.animation_fps = 240
  config.color_scheme = config_data.color_scheme
  config.cursor_blink_rate = 320
  config.cursor_thickness = 1
  config.font = font
  config.font_size = 12.0
  config.line_height = 1.0
  config.cell_width = 1.0
  
  -- OpenGL is more stable than WebGpu on NVIDIA+Wayland (wezterm #7017)
  config.front_end = "OpenGL"
  config.freetype_load_flags = "NO_HINTING|NO_AUTOHINT"
  
  config.macos_window_background_blur = utils.is_darwin() and config_data.transparency.blur or 0
  config.max_fps = 240
  config.quick_select_alphabet = "fjdkslaghrueiwoncmv"
  config.scrollback_lines = 200000
  config.tab_bar_at_bottom = true
  config.window_background_opacity = config_data.transparency.opacity
  config.window_decorations = utils.is_darwin() and "RESIZE|MACOS_FORCE_ENABLE_SHADOW" or "RESIZE"
  config.enable_wayland = true
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

  config.pane_focus_follows_mouse = false

  local function locked_indicator()
    if keybindings.locked_mode then
      return "  "
    end
    return "  "
  end

  local tabline_ok, tabline = pcall(wezterm.plugin.require, "https://github.com/michaelbrusegard/tabline.wez")
  if tabline_ok then
    tabline.setup({
      options = {
        theme = config_data.color_scheme,
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

  local agent_deck_ok, agent_deck = pcall(wezterm.plugin.require, "https://github.com/Eric162/wezterm-agent-deck")
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

  config.window_padding = {
    left = "0.5cell",
    right = "0.5cell",
    top = "0.5cell",
    bottom = "0.5cell",
  }

  -- Ensure wezterm fills its window on Wayland tiling WMs
  config.use_resize_increments = false

  -- Use default hyperlink rules (handles http/https, ssh, git, etc.)
  config.hyperlink_rules = wezterm.default_hyperlink_rules()
end

return M
