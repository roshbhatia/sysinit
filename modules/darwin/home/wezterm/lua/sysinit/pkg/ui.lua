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

  -- Use default hyperlink rules (handles http/https, ssh, git, etc.)
  config.hyperlink_rules = wezterm.default_hyperlink_rules()

  -- Handle custom URI schemes
  wezterm.on("open-uri", function(window, pane, uri)
    local function spawn_new_window(args)
      window:perform_action(wezterm.action.SpawnWindow({ args = args }), pane)
    end

    -- Git commit SHAs: show commit info in new window
    if uri:find("^git://") then
      local sha = uri:gsub("^git://", "")
      if sha:match("^[0-9a-f]+$") and #sha >= 7 and #sha <= 40 then
        spawn_new_window({
          "zsh",
          "-c",
          string.format("git show %s --stat --pretty=fuller || echo 'Not a valid git commit'", sha),
        })
        return false
      end
      return true
    end

    -- File paths: open in nvim in new window
    if uri:find("^file://") then
      local filepath = uri:gsub("^file://", "")

      -- Validate path before processing
      if not filepath or filepath == "" then
        wezterm.log_error("Invalid file path from hyperlink: " .. uri)
        return true
      end

      local nvim = utils.get_nix_binary("nvim")
      local dir = filepath:match("(.*/)")
      if dir then
        spawn_new_window({ "zsh", "-c", string.format("cd '%s' && %s '%s'", dir, nvim, filepath) })
      else
        spawn_new_window({ nvim, filepath })
      end
      return false
    end

    -- Images: display with chafa in new window
    local image_exts = { "png", "jpg", "jpeg", "gif", "bmp", "webp", "svg", "ico" }
    for _, ext in ipairs(image_exts) do
      if uri:lower():match("%." .. ext .. "$") or uri:lower():match("%." .. ext .. "[?#]") then
        local escaped = uri:gsub("'", "'\\''")
        spawn_new_window({
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
