local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

local function is_vim(pane)
  return pane:get_user_vars().IS_NVIM == "true"
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
    if is_vim(pane) then
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

local function get_pane_keys()
  return {
    -- Move
    { key = "h", mods = "CTRL", action = pane_keybinding("move", "h", "CTRL") },
    { key = "j", mods = "CTRL", action = pane_keybinding("move", "j", "CTRL") },
    { key = "k", mods = "CTRL", action = pane_keybinding("move", "k", "CTRL") },
    { key = "l", mods = "CTRL", action = pane_keybinding("move", "l", "CTRL") },
    -- Resize
    { key = "h", mods = "CTRL|SHIFT", action = pane_keybinding("resize", "h", "CTRL|SHIFT") },
    { key = "j", mods = "CTRL|SHIFT", action = pane_keybinding("resize", "j", "CTRL|SHIFT") },
    { key = "k", mods = "CTRL|SHIFT", action = pane_keybinding("resize", "k", "CTRL|SHIFT") },
    { key = "l", mods = "CTRL|SHIFT", action = pane_keybinding("resize", "l", "CTRL|SHIFT") },
    -- Splits
    {
      key = "s",
      mods = "CTRL",
      action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
    },
    {
      key = "v",
      mods = "CTRL",
      action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
    },
    -- Close
    {
      key = "w",
      mods = "CTRL",
      action = vim_or_wezterm_action("w", "CTRL", act.CloseCurrentPane({ confirm = true })),
    },
  }
end

local function get_clear_keys()
  return {
    {
      key = "k",
      mods = "CMD",
      action = wezterm.action_callback(function(win, pane)
        if is_vim(pane) then
          win:perform_action({
            SendKey = {
              key = "k",
              mods = "CMD",
            },
          }, pane)
        else
          win:perform_action(act.ClearScrollback("ScrollbackAndViewport"), pane)
        end
      end),
    },
    {
      key = "k",
      mods = "CTRL",
      action = wezterm.action_callback(function(win, pane)
        if is_vim(pane) then
          win:perform_action({
            SendKey = {
              key = "k",
              mods = "CTRL",
            },
          }, pane)
        else
          win:perform_action(act.ClearScrollback("ScrollbackAndViewport"), pane)
        end
      end),
    },
  }
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

local function get_scroll_keys()
  return {
    {
      key = "u",
      mods = "CTRL",
      action = wezterm.action_callback(function(win, pane)
        if is_vim(pane) then
          win:perform_action({
            SendKey = {
              key = "u",
              mods = "CTRL",
            },
          }, pane)
        else
          win:perform_action(act.ScrollByLine(-40), pane)
        end
      end),
    },
    {
      key = "d",
      mods = "CTRL",
      action = wezterm.action_callback(function(win, pane)
        if is_vim(pane) then
          win:perform_action({
            SendKey = {
              key = "d",
              mods = "CTRL",
            },
          }, pane)
        else
          win:perform_action(act.ScrollByLine(40), pane)
        end
      end),
    },
    {
      key = "u",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(function(win, pane)
        if is_vim(pane) then
          win:perform_action({
            SendKey = {
              key = "u",
              mods = "CTRL|SHIFT",
            },
          }, pane)
        else
          win:perform_action(act.ScrollByLine(-9999999999999), pane)
        end
      end),
    },
    {
      key = "d",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(function(win, pane)
        if is_vim(pane) then
          win:perform_action({
            SendKey = {
              key = "d",
              mods = "CTRL|SHIFT",
            },
          }, pane)
        else
          win:perform_action(act.ScrollByLine(9999999999999), pane)
        end
      end),
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
    {
      key = "w",
      mods = "CTRL|SHIFT",
      action = act.CloseCurrentTab({ confirm = true }),
    },
  }
end

local function get_tab_keys()
  return {
    {
      key = "t",
      mods = "CTRL",
      action = act.SpawnTab("CurrentPaneDomain"),
    },
    -- Tab cycling
    {
      key = "Tab",
      mods = "CTRL",
      action = act.ActivateTabRelative(1),
    },
    {
      key = "Tab",
      mods = "CTRL|SHIFT",
      action = act.ActivateTabRelative(-1),
    },
    -- Quick bracket navigation
    {
      key = "]",
      mods = "CTRL|SHIFT",
      action = act.ActivateTabRelative(1),
    },
    {
      key = "[",
      mods = "CTRL|SHIFT",
      action = act.ActivateTabRelative(-1),
    },
    -- Direct tab access
    {
      key = "1",
      mods = "CTRL",
      action = act.ActivateTab(0),
    },
    {
      key = "2",
      mods = "CTRL",
      action = act.ActivateTab(1),
    },
    {
      key = "3",
      mods = "CTRL",
      action = act.ActivateTab(2),
    },
    {
      key = "4",
      mods = "CTRL",
      action = act.ActivateTab(3),
    },
    {
      key = "5",
      mods = "CTRL",
      action = act.ActivateTab(4),
    },
    {
      key = "6",
      mods = "CTRL",
      action = act.ActivateTab(5),
    },
    {
      key = "7",
      mods = "CTRL",
      action = act.ActivateTab(6),
    },
    {
      key = "8",
      mods = "CTRL",
      action = act.ActivateTab(7),
    },
  }
end

local function get_search_keys()
  return {
    {
      key = "]",
      mods = "CTRL",
      action = act.ActivateCopyMode,
    },
    {
      key = "Enter",
      mods = "SHIFT",
      action = wezterm.action_callback(function(win, pane)
        if is_vim(pane) then
          win:perform_action({
            SendKey = {
              key = "Enter",
              mods = "SHIFT",
            },
          }, pane)
        else
          win:perform_action(act.QuickSelect)
        end
      end),
    },

    {
      key = "/",
      mods = "CTRL",
      action = act.Search("CurrentSelectionOrEmptyString"),
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

function M.setup(config)
  local all_keys = {}

  local key_groups = {
    get_pane_keys(),
    get_clear_keys(),
    get_pallete_keys(),
    get_scroll_keys(),
    get_window_keys(),
    get_tab_keys(),
    get_search_keys(),
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
