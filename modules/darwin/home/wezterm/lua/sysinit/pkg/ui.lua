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

  config.pane_focus_follows_mouse = false

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
  -- Not using default_hyperlink_rules() to avoid making all SHA hashes clickable indiscriminately
  config.hyperlink_rules = {
    -- HTTP/HTTPS URLs
    -- Matches: https://example.com, http://localhost:3000
    {
      regex = [[\bhttps?://\S+\b]],
      format = "$0",
    },

    -- Git commit SHAs (7-40 hex chars)
    -- Matches: 9239d87, 9239d87aa56a7d4240968ab7bef39ea8ccfa2641
    -- Uses git:// scheme to trigger custom handler
    {
      regex = [[\b[0-9a-f]{7,40}\b]],
      format = "git://$0",
    },

    -- Git protocols
    -- Matches: git://repo, git@github.com:user/repo
    {
      regex = [[\bgit[@:][\w.\-]+[:/][\w.\-/]+]],
      format = "$0",
    },

    -- SSH URLs
    -- Matches: ssh://user@host
    {
      regex = [[\bssh://\S+\b]],
      format = "$0",
    },

    -- Unix domain socket paths
    -- Matches: unix:///path/to/socket, unix:/var/run/docker.sock
    {
      regex = [[unix://[/\w\d.\-_]+]],
      format = "$0",
    },

    -- FTP paths
    -- Matches: ftp://ftp.example.com/path
    {
      regex = [[ftp://[^\s]+]],
      format = "$0",
    },

    -- Absolute file paths (starts with / or ~)
    -- Matches: /path/to/file, ~/documents/file.txt, /etc/config-*.yaml (optionally quoted)
    {
      regex = [=[["]?([\w\d]{1}[\w\d.\-_*?]+(/[\w\d.\-_*?]+)+)["]?]=],
      format = "file://$1",
    },

    -- Relative paths (starts with ./ or ../)
    -- Matches: ./file, ../parent/file, ./something-*.yaml, ../../another/path
    {
      regex = [=[\.\.?/[\w\d.\-_/*?]+]=],
      format = "file://$0",
    },
  }

  -- Handle custom URI schemes
  wezterm.on("open-uri", function(window, pane, uri)
    local function split_pane_right(args)
      window:perform_action(wezterm.action.SplitPane({ direction = "Right", command = { args = args } }), pane)
    end

    local function is_nvim_running()
      local fg = pane:get_foreground_process_name()
      return fg and fg:find("n?vim$")
    end

    -- Git commit SHAs: show commit info
    if uri:find("^git://") then
      local sha = uri:gsub("^git://", "")
      if sha:match("^[0-9a-f]+$") and #sha >= 7 and #sha <= 40 then
        split_pane_right({
          "zsh",
          "-c",
          string.format("git show %s --stat --pretty=fuller || echo 'Not a valid git commit'", sha),
        })
        return false
      end
      return true
    end

    -- File paths: open in nvim
    if uri:find("^file://") then
      local filepath = uri:gsub("^file://", "")

      if is_nvim_running() then
        local escaped = filepath:gsub("'", "''")
        window:perform_action(wezterm.action.SendString(string.format(":vsplit %s | Neotree reveal\r", escaped)), pane)
        return false
      end

      local dir = filepath:match("(.*/)")
      local nvim = utils.get_nix_binary("nvim")
      if dir then
        split_pane_right({ "zsh", "-c", string.format("cd '%s' && %s '%s'", dir, nvim, filepath) })
      else
        split_pane_right({ nvim, filepath })
      end
      return false
    end

    -- Images: display with chafa
    local image_exts = { "png", "jpg", "jpeg", "gif", "bmp", "webp", "svg", "ico" }
    for _, ext in ipairs(image_exts) do
      if uri:lower():match("%." .. ext .. "$") or uri:lower():match("%." .. ext .. "[?#]") then
        local escaped = uri:gsub("'", "'\\''")
        split_pane_right({
          "zsh",
          "-c",
          string.format("chafa '%s' 2>/dev/null || echo 'Failed to display image'", escaped),
        })
        return false
      end
    end

    -- Everything else: open with system handler
    local escaped = uri:gsub("'", "'\\''")
    local opener = utils.is_darwin() and "open" or "xdg-open"
    wezterm.background_child_process({ args = { "zsh", "-c", string.format("%s '%s'", opener, escaped) } })
    return false
  end)
end

return M
