local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

local function is_vim(pane)
  local process_name = string.gsub(pane:get_foreground_process_name(), "(.*[/\\])(.*)", "%2")
  return process_name == "nvim" or process_name == "vim"
end

local function is_zellij_running(pane)
  return os.getenv("ZELLIJ") ~= nil
end

local function vim_or_wezterm_action(key, mods, wezterm_action)
  return wezterm.action_callback(function(win, pane)
    if is_vim(pane) then
      win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
    else
      win:perform_action(wezterm_action, pane)
    end
  end)
end

local direction_keys = {
  h = "Left",
  j = "Down",
  k = "Up",
  l = "Right",
}

local function pane_keybinding(action_type, key, mods)
  return wezterm.action_callback(function(win, pane)
    local zellij_running = is_zellij_running(pane)

    if is_vim(pane) or zellij_running then
      win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
    else
      if action_type == "resize" then
        win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
      else
        win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
      end
    end
  end)
end

local function get_pallete_keys()
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
      key = "r",
      mods = "CMD",
      action = act.ReloadConfiguration,
    },
  }
end

local function zellij_aware_tab_action(key, mods, wezterm_action)
  return wezterm.action_callback(function(win, pane)
    local zellij_running = is_zellij_running(pane)

    if zellij_running then
      win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
    else
      win:perform_action(wezterm_action, pane)
    end
  end)
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

function M.setup(config)
  local all_keys = {}

  local key_groups = {
    get_pallete_keys(),
    get_window_keys(),
    get_transparency_keys(),
  }

  for _, group in ipairs(key_groups) do
    for _, key_binding in ipairs(group) do
      table.insert(all_keys, key_binding)
    end
  end

  config.keys = all_keys
end

return M
