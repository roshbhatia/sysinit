local wezterm = require("wezterm")

local keybindings = require("sysinit.pkg.keybindings")
local utils = require("sysinit.pkg.utils")

local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

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
  config.dpi = 144
  config.font = font
  config.font_size = 11.0
  config.macos_window_background_blur = utils.is_darwin() and config_data.transparency.blur or 0
  config.max_fps = 240
  config.quick_select_alphabet = "fjdkslaghrueiwoncmv"
  config.scrollback_lines = 200000
  config.tab_bar_at_bottom = true
  config.window_background_opacity = config_data.transparency.opacity
  config.window_decorations = utils.is_darwin() and "RESIZE|MACOS_FORCE_ENABLE_SHADOW" or "RESIZE"
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

  local function locked_indicator()
    if keybindings.locked_mode then
      return "  "
    end
    return "  "
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

  config.window_padding = {
    left = "1cell",
    right = "1cell",
    top = "1cell",
    bottom = "0cell",
  }

  -- Hyperlink rules for clickable URLs and file paths
  config.hyperlink_rules = wezterm.default_hyperlink_rules()

  -- Standard URL protocols (http, https, git, ssh, etc)
  -- Matches: https://example.com, ssh://user@host, git://repo, etc
  table.insert(config.hyperlink_rules, {
    regex = [[\b\w+://\S+\b]],
    format = "$0",
  })

  -- Unix domain socket paths
  -- Matches: unix:///path/to/socket, unix:/var/run/docker.sock
  table.insert(config.hyperlink_rules, {
    regex = [[unix://[/\w\d.\-_]+]],
    format = "$0",
  })

  -- SCP-style paths (user@host:/path or host:/path)
  -- Matches: user@example.com:/path/to/file, server:/var/log/app.log
  table.insert(config.hyperlink_rules, {
    regex = [[\b[\w\-\.]+@?[\w\-\.]+:\S+]],
    format = "scp://$0",
  })

  -- FTP paths
  -- Matches: ftp://ftp.example.com/path
  table.insert(config.hyperlink_rules, {
    regex = [[ftp://[^\s]+]],
    format = "$0",
  })

  -- Absolute file paths (starts with / or ~)
  -- Matches: /path/to/file, ~/documents/file.txt (optionally quoted)
  table.insert(config.hyperlink_rules, {
    regex = [=[["]?([\w\d]{1}[\w\d.\-_]+(/[\w\d.\-_]+)+)["]?]=],
    format = "file://$1",
  })

  -- Relative paths (starts with ./ or ../)
  -- Matches: ./file, ../parent/file, ../../another/path
  table.insert(config.hyperlink_rules, {
    regex = [=[\.\.?/[\w\d.\-_/]+]=],
    format = "file://$0",
  })

  -- Handle custom URI schemes
  wezterm.on("open-uri", function(window, pane, uri)
    -- Handle file:// URLs - open in nvim
    if uri:find("^file://") then
      local filepath = uri:gsub("^file://", "")
      local foreground_process = pane:get_foreground_process_name()

      -- If nvim is running, send :e command to open file in existing instance
      -- This allows flatten.nvim to handle the file opening
      if foreground_process and foreground_process:find("n?vim$") then
        window:perform_action(wezterm.action.SendString(string.format(":e %s\r", filepath)), pane)
        return false
      end

      -- Otherwise, spawn nvim in the current pane
      window:perform_action(
        wezterm.action.SendString(string.format("%s %s\r", utils.get_nix_binary("nvim"), filepath)),
        pane
      )
      return false
    end

    -- Handle scp:// URLs - send scp command to shell
    if uri:find("^scp://") then
      local scp_path = uri:gsub("^scp://", "")
      window:perform_action(wezterm.action.SendString(string.format("scp %s .\r", scp_path)), pane)
      return false
    end

    -- Let default handler handle other schemes (http, https, ftp, unix, etc)
    return true
  end)
end

return M
