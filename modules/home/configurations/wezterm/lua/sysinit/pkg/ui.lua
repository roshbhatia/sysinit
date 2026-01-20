local wezterm = require("wezterm")
local utils = require("sysinit.pkg.utils")

local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

local M = {}

local function get_foreground_executable(tab)
  for _, pane in ipairs(tab:panes()) do
    local info = pane:get_foreground_process_info()
    if info then
      return string.gsub(info.executable, "(.*[/\\])(.*)", "%2")
    end
  end
  return nil
end

local function should_apply_nvim_overrides(tab)
  local executable = get_foreground_executable(tab)
  return executable == "nvim" or executable == "tmux" or executable == "hx"
end

local function should_apply_k9s_overrides(tab)
  local executable = get_foreground_executable(tab)
  return executable == "k9s"
end

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
  config.animation_fps = 120
  config.color_scheme = config_data.color_scheme
  config.cursor_blink_rate = 320
  config.cursor_thickness = 1
  config.dpi = 144
  config.enable_scroll_bar = true
  config.font = font
  config.font_size = 13.0
  config.macos_window_background_blur = utils.is_darwin() and config_data.transparency.blur or 0
  config.max_fps = 240
  config.quick_select_alphabet = "fjdkslaghrueiwoncmv"
  config.scrollback_lines = 20000
  config.tab_bar_at_bottom = true
  config.window_background_opacity = config_data.transparency.opacity
  config.window_decorations = utils.is_darwin() and "RESIZE|MACOS_FORCE_ENABLE_SHADOW" or "RESIZE"
  config.window_frame = {
    font = font,
    font_size = 13.0,
  }
  config.visual_bell = {
    fade_in_function = "EaseIn",
    fade_in_duration_ms = 70,
    fade_out_function = "EaseOut",
    fade_out_duration_ms = 100,
  }

  local function locked_indicator()
    local keybindings = require("sysinit.pkg.keybindings")
    if keybindings.locked_mode then
      return {
        wezterm.nerdfonts.md_lock_alert,
      }
    end
    return {
      wezterm.nerdfonts.md_lock_open_variant_outline,
    }
  end

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
      tabline_a = { "mode", locked_indicator },
      tabline_x = {},
      tabline_y = {},
    },
    extensions = {},
  })
  tabline.apply_to_config(config)

  config.window_padding = {
    left = "1cell",
    right = "1cell",
    top = "1cell",
  }

  -- Configure hyperlink rules for file paths and URIs
  config.hyperlink_rules = {
    { regex = "\\b\\w+://(?:[\\w.-]+)\\.[a-z]{2,15}\\S*\\b", format = "$0" },
    { regex = "\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b", format = "mailto:$0" },
    { regex = "\\bfile://\\S*\\b", format = "$0" },
    { regex = "/[\\w./_-]+", format = "$EDITOR:$0" },
    { regex = "\\.[./][\\w./_-]+", format = "$EDITOR:$0" },
    {
      regex = "[\\w.-]+\\.(?:rs|ts|js|py|go|c|h|cpp|java|rb|lua|vim|nix|sh|bash|zsh|sql|json|yaml|yml|toml|xml|html|css|md|txt|log|env)",
      format = "$EDITOR:$0",
    },
    { regex = "[\\w./_-]+/", format = "$EDITOR:$0" },
  }

  local username = os.getenv("USER") or ""
  local nix_bin = "/etc/profiles/per-user/" .. username .. "/bin"
  wezterm.on("open-uri", function(window, pane, uri)
    if uri:sub(1, 8) == "$EDITOR:" then
      window:perform_action(wezterm.action.SpawnCommandInNewWindow({ args = { nix_bin .. "/nvim", uri:sub(9) } }), pane)
      return false
    end
    return true
  end)

  wezterm.on("update-status", function(window, pane)
    local tab = pane:tab()
    local overrides = window:get_config_overrides() or {}

    -- Apply nvim/tmux/hx overrides (hide scrollbar)
    local should_apply_nvim = should_apply_nvim_overrides(tab)
    overrides.enable_scroll_bar = should_apply_nvim and false or nil

    -- Apply k9s overrides (full opacity)
    local should_apply_k9s = should_apply_k9s_overrides(tab)
    overrides.window_background_opacity = should_apply_k9s and 1.0 or nil

    window:set_config_overrides(overrides)
  end)
end

return M
