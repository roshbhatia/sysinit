local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local function get_palette_keys()
  return {
    {
      key = "/",
      mods = "CTRL|SHIFT",
      action = act.ActivateCommandPalette,
    },
  }
end

local function get_window_keys()
  return {
    {
      key = "n",
      mods = "CTRL",
      action = act.SpawnWindow,
    },
    {
      key = "n",
      mods = "SUPER",
      action = act.SpawnWindow,
    },
  }
end

local function get_transparency_keys()
  return {
    {
      key = "t",
      mods = "CTRL|ALT",
      action = wezterm.action_callback(function(win, pane)
        local overrides = win:get_config_overrides() or {}
        local current_opacity = overrides.window_background_opacity or 1.0

        if current_opacity == 1.0 then
          overrides.window_background_opacity = 0.85
          overrides.macos_window_background_blur = 80
        else
          overrides.window_background_opacity = 1.0
          overrides.macos_window_background_blur = 0
        end

        win:set_config_overrides(overrides)
      end),
    },
  }
end

local function get_clipboard_keys()
  return {
    {
      key = "c",
      mods = "SUPER",
      action = act.CopyTo("Clipboard"),
    },
    {
      key = "v",
      mods = "SUPER",
      action = act.PasteFrom("Clipboard"),
    },
  }
end

local function get_font_keys()
  return {
    {
      key = "-",
      mods = "SUPER",
      action = act.DecreaseFontSize,
    },
    {
      key = "-",
      mods = "CTRL",
      action = act.DecreaseFontSize,
    },
    {
      key = "=",
      mods = "SUPER",
      action = act.IncreaseFontSize,
    },
    {
      key = "=",
      mods = "CTRL",
      action = act.IncreaseFontSize,
    },
    {
      key = "0",
      mods = "SUPER",
      action = act.ResetFontSize,
    },
    {
      key = "0",
      mods = "CTRL",
      action = act.ResetFontSize,
    },
  }
end

local function get_app_control_keys()
  return {
    {
      key = "h",
      mods = "SUPER",
      action = act.HideApplication,
    },
  }
end

function M.setup(config)
  local all_keys = {}

  local key_groups = {
    get_palette_keys(),
    get_window_keys(),
    get_transparency_keys(),
    get_clipboard_keys(),
    get_font_keys(),
    get_app_control_keys(),
  }

  for _, group in ipairs(key_groups) do
    for _, key_binding in ipairs(group) do
      table.insert(all_keys, key_binding)
    end
  end

  config.disable_default_key_bindings = true
  config.keys = all_keys
end

return M
