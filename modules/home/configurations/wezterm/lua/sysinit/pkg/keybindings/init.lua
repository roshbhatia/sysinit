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
    {
      key = "w",
      mods = "SUPER|SHIFT",
      action = act.CloseCurrentTab({ confirm = true }),
    },
    {
      key = "w",
      mods = "CTRL|SHIFT",
      action = act.CloseCurrentTab({ confirm = true }),
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
    {
      key = "q",
      mods = "SUPER",
      action = act.QuitApplication,
    },
  }
end

local function get_zellij_passthrough_keys()
  return {
    {
      key = "t",
      mods = "CMD",
      action = act.SendKey({ key = "t", mods = "SUPER" }),
    },
    {
      key = "t",
      mods = "CTRL",
      action = act.SendKey({ key = "t", mods = "CTRL" }),
    },
    {
      key = "k",
      mods = "CMD",
      action = act.SendKey({ key = "k", mods = "SUPER" }),
    },
    {
      key = "l",
      mods = "CTRL",
      action = act.SendKey({ key = "l", mods = "CTRL" }),
    },
    {
      key = "f",
      mods = "CMD",
      action = act.SendKey({ key = "f", mods = "CTRL" }),
    },
    {
      key = "f",
      mods = "CTRL",
      action = act.SendKey({ key = "f", mods = "CTRL" }),
    },
    {
      key = "/",
      mods = "CMD",
      action = act.SendKey({ key = "/", mods = "CTRL" }),
    },
    {
      key = "/",
      mods = "CTRL",
      action = act.SendKey({ key = "/", mods = "CTRL" }),
    },
    {
      key = "1",
      mods = "CMD",
      action = act.SendKey({ key = "1", mods = "SUPER" }),
    },
    {
      key = "2",
      mods = "CMD",
      action = act.SendKey({ key = "2", mods = "SUPER" }),
    },
    {
      key = "3",
      mods = "CMD",
      action = act.SendKey({ key = "3", mods = "SUPER" }),
    },
    {
      key = "4",
      mods = "CMD",
      action = act.SendKey({ key = "4", mods = "SUPER" }),
    },
    {
      key = "5",
      mods = "CMD",
      action = act.SendKey({ key = "5", mods = "SUPER" }),
    },
    {
      key = "6",
      mods = "CMD",
      action = act.SendKey({ key = "6", mods = "SUPER" }),
    },
    {
      key = "7",
      mods = "CMD",
      action = act.SendKey({ key = "7", mods = "SUPER" }),
    },
    {
      key = "8",
      mods = "CMD",
      action = act.SendKey({ key = "8", mods = "SUPER" }),
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
    get_zellij_passthrough_keys(),
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
