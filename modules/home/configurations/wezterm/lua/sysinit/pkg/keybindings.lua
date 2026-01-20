local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local PASSTHROUGH_PROCESSES = { "nvim", "vim", "hx", "k9s" }
local VIM_PROCESSES = { "nvim", "vim" }
local GOOSE_PROCESS = "goose"

-- Global state for locked mode
M.locked_mode = false

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

local function create_lockable_action(key, mods, wezterm_action)
  return wezterm.action_callback(function(win, pane)
    if M.locked_mode then
      win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
    else
      win:perform_action(wezterm_action, pane)
    end
  end)
end

local function create_passthrough_action(key, mods, wezterm_action, process_list)
  return wezterm.action_callback(function(win, pane)
    if M.locked_mode or is_process_in_list(pane, process_list or PASSTHROUGH_PROCESSES) then
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

local function create_pane_action(action_type, key, mods)
  return wezterm.action_callback(function(win, pane)
    if M.locked_mode or is_process_in_list(pane, PASSTHROUGH_PROCESSES) then
      win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
    else
      local action = action_type == "resize" and { AdjustPaneSize = { DIRECTION_KEYS[key], 3 } }
        or { ActivatePaneDirection = DIRECTION_KEYS[key] }
      win:perform_action(action, pane)
    end
  end)
end

local function get_pane_keys()
  local keys = {
    {
      key = "s",
      mods = "CTRL",
      action = create_lockable_action("s", "CTRL", act.SplitVertical({ domain = "CurrentPaneDomain" })),
    },
    {
      key = "v",
      mods = "CTRL",
      action = create_lockable_action("v", "CTRL", act.SplitHorizontal({ domain = "CurrentPaneDomain" })),
    },
    {
      key = "m",
      mods = "CTRL",
      action = create_lockable_action("m", "CTRL", act.TogglePaneZoomState),
    },
  }

  for _, key in ipairs({ "h", "j", "k", "l" }) do
    table.insert(keys, { key = key, mods = "CTRL", action = create_pane_action("move", key, "CTRL") })
    table.insert(keys, { key = key, mods = "CTRL|SHIFT", action = create_pane_action("resize", key, "CTRL|SHIFT") })
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
    { key = "c", mods = "SUPER", action = create_lockable_action("c", "SUPER", act.CopyTo("Clipboard")) },
    { key = "v", mods = "SUPER", action = create_lockable_action("v", "SUPER", act.PasteFrom("Clipboard")) },
    { key = "m", mods = "SUPER", action = create_lockable_action("m", "SUPER", act.Hide) },
    { key = "h", mods = "SUPER", action = create_lockable_action("h", "SUPER", act.HideApplication) },
    { key = "q", mods = "SUPER", action = create_lockable_action("q", "SUPER", act.QuitApplication) },
    { key = ";", mods = "CTRL", action = create_lockable_action(";", "CTRL", act.ActivateCommandPalette) },
    { key = "l", mods = "CTRL|SHIFT", action = create_lockable_action("l", "CTRL|SHIFT", act.ShowDebugOverlay) },
    {
      key = "k",
      mods = "SUPER",
      action = create_passthrough_action("k", "CTRL", act.ClearScrollback("ScrollbackAndViewport")),
    },
    {
      key = "Enter",
      mods = "SHIFT",
      action = wezterm.action_callback(function(win, pane)
        if M.locked_mode then
          return
        end
        if is_process_in_list(pane, { GOOSE_PROCESS }) then
          win:perform_action({ SendKey = { key = "j", mods = "CTRL" } }, pane)
        end
      end),
    },
  }
end

local function get_font_keys()
  local keys = {}
  for _, mods in ipairs({ "CTRL", "SUPER" }) do
    table.insert(keys, { key = "-", mods = mods, action = create_lockable_action("-", mods, act.DecreaseFontSize) })
    table.insert(keys, { key = "=", mods = mods, action = create_lockable_action("=", mods, act.IncreaseFontSize) })
  end
  return keys
end

local function get_tab_keys()
  local keys = {
    {
      key = "w",
      mods = "CTRL|SHIFT",
      action = create_lockable_action("w", "CTRL|SHIFT", act.CloseCurrentTab({ confirm = true })),
    },
    { key = "Tab", mods = "CTRL", action = create_lockable_action("Tab", "CTRL", act.ActivateTabRelative(1)) },
    {
      key = "Tab",
      mods = "CTRL|SHIFT",
      action = create_lockable_action("Tab", "CTRL|SHIFT", act.ActivateTabRelative(-1)),
    },
    { key = "o", mods = "CTRL|SHIFT", action = create_lockable_action("o", "CTRL|SHIFT", act.ActivateLastTab) },
  }

  for _, mods in ipairs({ "CTRL", "SUPER" }) do
    table.insert(
      keys,
      { key = "t", mods = mods, action = create_lockable_action("t", mods, act.SpawnTab("CurrentPaneDomain")) }
    )
  end

  for i = 1, 8 do
    for _, mods in ipairs({ "CTRL", "SUPER" }) do
      table.insert(
        keys,
        { key = tostring(i), mods = mods, action = create_lockable_action(tostring(i), mods, act.ActivateTab(i - 1)) }
      )
    end
  end

  for _, mods in ipairs({ "CTRL", "SUPER" }) do
    table.insert(keys, { key = "9", mods = mods, action = create_lockable_action("9", mods, act.ActivateTab(-1)) })
  end

  return keys
end

local function get_window_keys()
  local keys = {}
  for _, mods in ipairs({ "CTRL", "SUPER" }) do
    table.insert(keys, { key = "n", mods = mods, action = create_lockable_action("n", mods, act.SpawnWindow) })
  end
  return keys
end

local function get_search_keys()
  return {
    { key = "Escape", mods = "CTRL", action = create_lockable_action("Escape", "CTRL", act.ActivateCopyMode) },
    {
      key = "/",
      mods = "CTRL",
      action = create_lockable_action("/", "CTRL", act.Search("CurrentSelectionOrEmptyString")),
    },
    { key = "f", mods = "CTRL", action = create_lockable_action("f", "CTRL", act.PaneSelect) },
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

  local all_keys = {}
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

  -- Add Ctrl+g to toggle locked mode
  table.insert(all_keys, {
    key = "g",
    mods = "CTRL",
    action = wezterm.action_callback(function(_, _)
      M.locked_mode = not M.locked_mode
    end),
  })

  config.keys = all_keys
  config.key_tables = wezterm.gui and wezterm.gui.default_key_tables() or {}
end

return M
