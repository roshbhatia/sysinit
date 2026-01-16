local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local PASSTHROUGH_PROCESSES = { "nvim", "vim", "hx", "k9s" }
local VIM_PROCESSES = { "nvim", "vim" }
local GOOSE_PROCESS = "goose"

local function get_process_name(pane)
  local proc = pane:get_foreground_process_name()
  if not proc then
    return nil
  end
  return proc:match("([^/\\]+)$")
end

local function is_process_in_list(pane, process_list)
  local process_name = get_process_name(pane)
  if not process_name then
    return false
  end
  for _, proc in ipairs(process_list) do
    if process_name == proc then
      return true
    end
  end
  return false
end

local function create_passthrough_action(key, mods, wezterm_action, process_list)
  return wezterm.action_callback(function(win, pane)
    if is_process_in_list(pane, process_list or PASSTHROUGH_PROCESSES) then
      win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
    else
      win:perform_action(wezterm_action, pane)
    end
  end)
end

local DIRECTION_KEYS = {
  h = "Left",
  j = "Down",
  k = "Up",
  l = "Right",
}

local function create_pane_action(action_type, key)
  return wezterm.action_callback(function(win, pane)
    if is_process_in_list(pane, PASSTHROUGH_PROCESSES) then
      win:perform_action({ SendKey = { key = "a", mods = "CTRL" } }, pane)
      win:perform_action({ SendKey = { key = key } }, pane)
    else
      local action = action_type == "resize" and { AdjustPaneSize = { DIRECTION_KEYS[key:lower()], 3 } }
        or { ActivatePaneDirection = DIRECTION_KEYS[key] }
      win:perform_action(action, pane)
    end
  end)
end

local function create_multi_bindings(key, mods_list, action)
  local bindings = {}
  for _, mods in ipairs(mods_list) do
    table.insert(bindings, { key = key, mods = mods, action = action })
  end
  return bindings
end

local function get_pane_keys()
  local keys = {
    { key = "s", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
    { key = "v", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
    { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
  }

  for _, key in ipairs({ "h", "j", "k", "l" }) do
    table.insert(keys, { key = key, mods = "LEADER", action = create_pane_action("move", key) })
    table.insert(keys, { key = key:upper(), mods = "LEADER|SHIFT", action = create_pane_action("resize", key:upper()) })
  end

  for _, mods in ipairs({ "CTRL", "SUPER" }) do
    table.insert(keys, {
      key = "w",
      mods = mods,
      action = create_passthrough_action("w", mods, act.CloseCurrentPane({ confirm = true }), VIM_PROCESSES),
    })
  end

  return keys
end

local function get_system_keys()
  return {
    { key = "c", mods = "SUPER", action = act.CopyTo("Clipboard") },
    { key = "v", mods = "SUPER", action = act.PasteFrom("Clipboard") },
    { key = "m", mods = "SUPER", action = act.Hide },
    { key = "h", mods = "SUPER", action = act.HideApplication },
    { key = "q", mods = "SUPER", action = act.QuitApplication },
    { key = ";", mods = "LEADER", action = act.ActivateCommandPalette },
    { key = "l", mods = "LEADER", action = act.ShowDebugOverlay },
    { key = "r", mods = "LEADER", action = act.ReloadConfiguration },
    {
      key = "k",
      mods = "SUPER",
      action = create_passthrough_action("k", "CTRL", act.ClearScrollback("ScrollbackAndViewport")),
    },
    {
      key = "Enter",
      mods = "SHIFT",
      action = wezterm.action_callback(function(win, pane)
        if is_process_in_list(pane, { GOOSE_PROCESS }) then
          win:perform_action({ SendKey = { key = "j", mods = "CTRL" } }, pane)
        end
      end),
    },
  }
end

local function get_font_keys()
  local keys = {}
  for _, binding in ipairs(create_multi_bindings("-", { "CTRL", "SUPER" }, act.DecreaseFontSize)) do
    table.insert(keys, binding)
  end
  for _, binding in ipairs(create_multi_bindings("=", { "CTRL", "SUPER" }, act.IncreaseFontSize)) do
    table.insert(keys, binding)
  end
  return keys
end

local function get_tab_keys()
  local keys = {
    { key = "w", mods = "LEADER", action = act.CloseCurrentTab({ confirm = true }) },
    { key = "t", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
  }

  for i = 1, 9 do
    table.insert(keys, {
      key = tostring(i),
      mods = "LEADER",
      action = act.ActivateTab(i - 1),
    })
  end

  return keys
end

local function get_window_keys()
  return create_multi_bindings("n", { "CTRL", "SUPER" }, act.SpawnWindow)
end

local function get_search_keys()
  return {
    { key = "Escape", mods = "CTRL", action = act.ActivateCopyMode },
    { key = "/", mods = "CTRL", action = act.Search("CurrentSelectionOrEmptyString") },
    { key = "f", mods = "CTRL", action = act.PaneSelect },
  }
end

local function get_scroll_keys()
  return {
    {
      key = "u",
      mods = "CTRL",
      action = create_passthrough_action("u", "CTRL", act.ScrollByLine(-40)),
    },
    {
      key = "d",
      mods = "CTRL",
      action = create_passthrough_action("d", "CTRL", act.ScrollByLine(40)),
    },
    {
      key = "u",
      mods = "CTRL|SHIFT",
      action = create_passthrough_action("u", "CTRL|SHIFT", act.ScrollToTop),
    },
    {
      key = "d",
      mods = "CTRL|SHIFT",
      action = create_passthrough_action("d", "CTRL|SHIFT", act.ScrollToBottom),
    },
  }
end

function M.setup(config)
  config.disable_default_key_bindings = true
  config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

  local all_keys = {
    { key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },
  }

  local key_groups = {
    get_system_keys(),
    get_font_keys(),
    get_pane_keys(),
    get_scroll_keys(),
    get_search_keys(),
    get_tab_keys(),
    get_window_keys(),
  }

  for _, group in ipairs(key_groups) do
    for _, key_binding in ipairs(group) do
      table.insert(all_keys, key_binding)
    end
  end

  config.keys = all_keys
  config.key_tables = wezterm.gui and wezterm.gui.default_key_tables() or {}
end

return M
