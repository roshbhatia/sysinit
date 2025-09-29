local wezterm = require("wezterm")
local act = wezterm.action
local M = {}
local ProcessDetector = {}

function ProcessDetector.get_process_name(pane)
  local full_name = pane:get_foreground_process_name()
  return string.gsub(full_name, "(.*[/\\])(.*)", "%2")
end

local process_detectors = {
  function(pane)
    local process_name = ProcessDetector.get_process_name(pane)
    return process_name == "nvim" or process_name == "vim"
  end,
  function(pane)
    local process_name = ProcessDetector.get_process_name(pane)
    return process_name == "k9s"
  end,
  function(pane)
    local process_name = ProcessDetector.get_process_name(pane)
    local terminal_apps = { "htop", "btop", "top", "less", "more", "man", "git", "tmux", "screen" }
    for _, app in ipairs(terminal_apps) do
      if process_name == app then
        return true
      end
    end
    return false
  end,
}

function ProcessDetector.should_send_key_directly(pane)
  for _, detector in ipairs(process_detectors) do
    if detector(pane) then
      return true
    end
  end
  return false
end

function ProcessDetector.is_vim(pane)
  local process_name = ProcessDetector.get_process_name(pane)
  return process_name == "nvim" or process_name == "vim"
end

function ProcessDetector.is_k9s(pane)
  local process_name = ProcessDetector.get_process_name(pane)
  return process_name == "k9s"
end

local function smart_action(key, mods, wezterm_action)
  return wezterm.action_callback(function(win, pane)
    if ProcessDetector.should_send_key_directly(pane) then
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
    if ProcessDetector.should_send_key_directly(pane) then
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
      action = smart_action("w", "CTRL", act.CloseCurrentPane({ confirm = true })),
    },
    {
      key = "w",
      mods = "CMD",
      action = smart_action("w", "CTRL", act.CloseCurrentPane({ confirm = true })),
    },
  }
end

local function get_clear_keys()
  return {
    {
      key = "k",
      mods = "CMD",
      action = smart_action("k", "CMD", act.ClearScrollback("ScrollbackAndViewport")),
    },
    {
      key = "k",
      mods = "CTRL",
      action = smart_action("k", "CTRL", act.ClearScrollback("ScrollbackAndViewport")),
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
      action = smart_action("u", "CTRL", act.ScrollByLine(-40)),
    },
    {
      key = "d",
      mods = "CTRL",
      action = smart_action("d", "CTRL", act.ScrollByLine(40)),
    },
    {
      key = "u",
      mods = "CTRL|SHIFT",
      action = smart_action("u", "CTRL|SHIFT", act.ScrollByLine(-9999999999999)),
    },
    {
      key = "d",
      mods = "CTRL|SHIFT",
      action = smart_action("d", "CTRL|SHIFT", act.ScrollByLine(9999999999999)),
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
      key = "5",
      mods = "CTRL|SHIFT",
      action = act.ActivateCopyMode,
    },
    {
      key = "Enter",
      mods = "SHIFT",
      action = smart_action("Enter", "SHIFT", act.QuickSelect),
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

local function get_agent_keys()
  return {
    {
      key = "i",
      mods = "CMD",
      action = wezterm.action({ SendString = "\x1b\r" }),
    },
    {
      key = "i",
      mods = "CTRL",
      action = wezterm.action({ SendString = "\x1b\r" }),
    },
  }
end

local function get_k9s_keys()
  return {
    -- Ctrl+D for k9s (quit/exit)
    {
      key = "d",
      mods = "CTRL",
      action = wezterm.action_callback(function(win, pane)
        if ProcessDetector.is_k9s(pane) then
          win:perform_action({ SendKey = { key = "d", mods = "CTRL" } }, pane)
        else
          win:perform_action(act.ScrollByLine(40), pane)
        end
      end),
    },
    -- Ctrl+C for k9s (cancel/back)
    {
      key = "c",
      mods = "CTRL",
      action = wezterm.action_callback(function(win, pane)
        if ProcessDetector.is_k9s(pane) then
          win:perform_action({ SendKey = { key = "c", mods = "CTRL" } }, pane)
        else
          win:perform_action(act.CopyTo("Clipboard"), pane)
        end
      end),
    },
    -- Escape for k9s (back/cancel)
    {
      key = "Escape",
      mods = "NONE",
      action = wezterm.action_callback(function(win, pane)
        if ProcessDetector.is_k9s(pane) then
          win:perform_action({ SendKey = { key = "Escape", mods = "NONE" } }, pane)
        else
          win:perform_action(act.CopyMode("Close"), pane)
        end
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
    get_agent_keys(),
    get_k9s_keys(),
  }

  for _, group in ipairs(key_groups) do
    for _, key_binding in ipairs(group) do
      table.insert(all_keys, key_binding)
    end
  end

  config.keys = all_keys
end

return M
