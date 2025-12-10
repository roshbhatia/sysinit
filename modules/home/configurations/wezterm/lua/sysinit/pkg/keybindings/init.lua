local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

local function should_passthrough(pane)
  local process_name = string.gsub(pane:get_foreground_process_name(), "(.*[/\\])(.*)", "%2")
  return process_name == "nvim"
    or process_name == "vim"
    or process_name == "hx"
    or process_name == "k9s"
end

local function vim_or_wezterm_action(key, mods, wezterm_action)
  return wezterm.action_callback(function(win, pane)
    if should_passthrough(pane) then
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
    if should_passthrough(pane) then
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
  vim_or_wezterm_action("w", "CTRL", act.CloseCurrentPane({ confirm = true }))
  vim_or_wezterm_action("w", "CMD", act.CloseCurrentPane({ confirm = true }))

  return {
    { key = "h", mods = "CTRL", action = pane_keybinding("move", "h", "CTRL") },
    { key = "j", mods = "CTRL", action = pane_keybinding("move", "j", "CTRL") },
    { key = "k", mods = "CTRL", action = pane_keybinding("move", "k", "CTRL") },
    { key = "l", mods = "CTRL", action = pane_keybinding("move", "l", "CTRL") },
    { key = "h", mods = "CTRL|SHIFT", action = pane_keybinding("resize", "h", "CTRL|SHIFT") },
    { key = "j", mods = "CTRL|SHIFT", action = pane_keybinding("resize", "j", "CTRL|SHIFT") },
    { key = "k", mods = "CTRL|SHIFT", action = pane_keybinding("resize", "k", "CTRL|SHIFT") },
    { key = "l", mods = "CTRL|SHIFT", action = pane_keybinding("resize", "l", "CTRL|SHIFT") },
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
  }
end

local function get_clear_keys()
  local clear_action = wezterm.action_callback(function(win, pane)
    if should_passthrough(pane) then
      win:perform_action({
        SendKey = {
          key = "k",
          mods = "CMD",
        },
      }, pane)
    else
      win:perform_action(act.ClearScrollback("ScrollbackAndViewport"), pane)
    end
  end)

  return {
    {
      key = "k",
      mods = "CMD",
      action = clear_action,
    },
  }
end

local function get_pallete_keys()
  return {
    {
      key = "Space",
      mods = "CTRL|SHIFT",
      action = act.ActivateCommandPalette,
    },
  }
end

local function get_window_keys()
  return {
    {
      key = "n",
      mods = "CMD",
      action = act.SpawnWindow,
    },
    {
      key = "w",
      mods = "CMD",
      action = act.CloseCurrentTab({ confirm = false }),
    },
  }
end

local function get_tab_keys()
  return {
    {
      key = "t",
      mods = "CMD",
      action = act.SpawnTab("CurrentPaneDomain"),
    },
    {
      key = "]",
      mods = "CMD|SHIFT",
      action = act.ActivateTabRelative(1),
    },
    {
      key = "[",
      mods = "CMD|SHIFT",
      action = act.ActivateTabRelative(-1),
    },
    -- Direct tab access
    {
      key = "1",
      mods = "CMD",
      action = act.ActivateTab(0),
    },
    {
      key = "2",
      mods = "CMD",
      action = act.ActivateTab(1),
    },
    {
      key = "3",
      mods = "CMD",
      action = act.ActivateTab(2),
    },
    {
      key = "4",
      mods = "CMD",
      action = act.ActivateTab(3),
    },
    {
      key = "5",
      mods = "CMD",
      action = act.ActivateTab(4),
    },
    {
      key = "6",
      mods = "CMD",
      action = act.ActivateTab(5),
    },
    {
      key = "7",
      mods = "CMD",
      action = act.ActivateTab(6),
    },
    {
      key = "8",
      mods = "CMD",
      action = act.ActivateTab(7),
    },
  }
end

local function with_tattoy_disabled(action)
  return act.Multiple({
    act.SendKey({ key = "F1" }),
    action,
  })
end

local function get_search_keys()
  return {
    {
      key = "Escape",
      mods = "CTRL",
      action = with_tattoy_disabled(act.ActivateCopyMode),
    },
    {
      key = "Escape",
      mods = "CMD",
      action = with_tattoy_disabled(act.ActivateCopyMode),
    },
    {
      key = "f",
      mods = "CTRL",
      action = with_tattoy_disabled(act.QuickSelect),
    },
    {
      key = "f",
      mods = "CMD",
      action = with_tattoy_disabled(act.QuickSelect),
    },
    {
      key = "/",
      mods = "CTRL",
      action = with_tattoy_disabled(act.Search("CurrentSelectionOrEmptyString")),
    },
    {
      key = "/",
      mods = "CMD",
      action = with_tattoy_disabled(act.Search("CurrentSelectionOrEmptyString")),
    },
  }
end

local function get_transparency_keys()
  return {
    {
      key = "t",
      mods = "CTRL|ALT",
      action = wezterm.action_callback(function(win)
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

local function get_key_tables()
  if not wezterm.gui then
    return {}
  end

  local defaults = wezterm.gui.default_key_tables()

  local function patch_exit_keys(key_table, exit_keys)
    for i, binding in ipairs(key_table) do
      local key = binding.key
      local mods = binding.mods or "NONE"

      for _, exit_def in ipairs(exit_keys) do
        if key == exit_def.key and mods == (exit_def.mods or "NONE") then
          key_table[i].action = act.Multiple({
            binding.action,
            act.SendKey({ key = "F1" }),
          })
          break
        end
      end
    end
    return key_table
  end

  local copy_mode_exits = {
    { key = "Escape" },
    { key = "q" },
    { key = "c", mods = "CTRL" },
    { key = "g", mods = "CTRL" },
  }

  local search_mode_exits = {
    { key = "Escape" },
    { key = "Enter" },
    { key = "r", mods = "CTRL" },
  }

  return {
    copy_mode = patch_exit_keys(defaults.copy_mode, copy_mode_exits),
    search_mode = patch_exit_keys(defaults.search_mode, search_mode_exits),
  }
end

function M.setup(config)
  local all_keys = {}

  local key_groups = {
    get_pane_keys(),
    get_clear_keys(),
    get_pallete_keys(),
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
  config.key_tables = get_key_tables()
end

return M
