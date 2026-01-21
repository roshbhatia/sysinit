local wezterm = require("wezterm")
local act = wezterm.action
local utils = require("sysinit.pkg.utils")

local M = {}

M.locked_mode = false

local function is_goose(pane)
  return utils.get_process_name(pane) == "goose"
end

-- Process lists for passthrough behavior
local EDITORS = { "nvim", "vim", "hx" }

-- Unified action builder
-- @param key: the key
-- @param mods: modifiers
-- @param wezterm_action: action to perform when NOT locked and NOT passthrough
-- @param opts: optional table with:
--   - passthrough: list of process names to pass through to (e.g., EDITORS)
local function create_smart_action(key, mods, wezterm_action, opts)
  return wezterm.action_callback(function(win, pane)
    -- Locked mode: always send key to pane
    if M.locked_mode then
      win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
      return
    end

    -- Check passthrough processes
    if opts and opts.passthrough then
      local proc = utils.get_process_name(pane)
      for _, p in ipairs(opts.passthrough) do
        if proc == p then
          win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
          return
        end
      end
    end

    -- Default: use wezterm action
    win:perform_action(wezterm_action, pane)
  end)
end

local function get_goose_keys()
  return {
    {
      key = "Enter",
      mods = "SHIFT",
      action = wezterm.action_callback(function(win, pane)
        if M.locked_mode then
          return
        end
        if is_goose(pane) then
          win:perform_action({ SendKey = { key = "j", mods = "CTRL" } }, pane)
        end
      end),
    },
  }
end

local function get_pane_keys()
  local DIRECTION_KEYS = { h = "Left", j = "Down", k = "Up", l = "Right" }
  local keys = {
    {
      key = "s",
      mods = "CTRL",
      action = create_smart_action("s", "CTRL", act.SplitVertical({ domain = "CurrentPaneDomain" })),
    },
    {
      key = "v",
      mods = "CTRL",
      action = create_smart_action("v", "CTRL", act.SplitHorizontal({ domain = "CurrentPaneDomain" })),
    },
    {
      key = "m",
      mods = "CTRL",
      action = create_smart_action("m", "CTRL", act.TogglePaneZoomState),
    },
  }

  for _, key in ipairs({ "h", "j", "k", "l" }) do
    table.insert(keys, {
      key = key,
      mods = "CTRL",
      action = create_smart_action(
        key,
        "CTRL",
        { ActivatePaneDirection = DIRECTION_KEYS[key] },
        { passthrough = EDITORS }
      ),
    })
    table.insert(keys, {
      key = key,
      mods = "CTRL|SHIFT",
      action = create_smart_action(
        key,
        "CTRL|SHIFT",
        { AdjustPaneSize = { DIRECTION_KEYS[key], 3 } },
        { passthrough = EDITORS }
      ),
    })
  end

  for _, mods in ipairs({ "CTRL", "SUPER" }) do
    table.insert(keys, {
      key = "w",
      mods = mods,
      action = create_smart_action("w", mods, act.CloseCurrentPane({ confirm = true })),
    })
  end

  return keys
end

local function get_system_keys()
  return {
    { key = "c", mods = "SUPER", action = create_smart_action("c", "SUPER", act.CopyTo("Clipboard")) },
    { key = "v", mods = "SUPER", action = create_smart_action("v", "SUPER", act.PasteFrom("Clipboard")) },
    { key = "m", mods = "SUPER", action = create_smart_action("m", "SUPER", act.Hide) },
    { key = "h", mods = "SUPER", action = create_smart_action("h", "SUPER", act.HideApplication) },
    { key = "q", mods = "SUPER", action = create_smart_action("q", "SUPER", act.QuitApplication) },
    { key = ";", mods = "CTRL", action = create_smart_action(";", "CTRL", act.ActivateCommandPalette) },
    { key = "l", mods = "CTRL|SHIFT", action = create_smart_action("l", "CTRL|SHIFT", act.ShowDebugOverlay) },
    {
      key = "k",
      mods = "SUPER",
      action = create_smart_action("k", "SUPER", act.ClearScrollback("ScrollbackAndViewport")),
    },
  }
end

local function get_font_keys()
  local keys = {}
  for _, mods in ipairs({ "CTRL", "SUPER" }) do
    table.insert(keys, { key = "-", mods = mods, action = create_smart_action("-", mods, act.DecreaseFontSize) })
    table.insert(keys, { key = "=", mods = mods, action = create_smart_action("=", mods, act.IncreaseFontSize) })
  end
  return keys
end

local function get_tab_keys()
  local keys = {
    {
      key = "w",
      mods = "CTRL|SHIFT",
      action = create_smart_action("w", "CTRL|SHIFT", act.CloseCurrentTab({ confirm = true })),
    },
    { key = "Tab", mods = "CTRL", action = create_smart_action("Tab", "CTRL", act.ActivateTabRelative(1)) },
    {
      key = "Tab",
      mods = "CTRL|SHIFT",
      action = create_smart_action("Tab", "CTRL|SHIFT", act.ActivateTabRelative(-1)),
    },
    { key = "o", mods = "CTRL|SHIFT", action = create_smart_action("o", "CTRL|SHIFT", act.ActivateLastTab) },
  }

  for _, mods in ipairs({ "CTRL", "SUPER" }) do
    table.insert(
      keys,
      { key = "t", mods = mods, action = create_smart_action("t", mods, act.SpawnTab("CurrentPaneDomain")) }
    )
  end

  for i = 1, 8 do
    for _, mods in ipairs({ "CTRL", "SUPER" }) do
      table.insert(
        keys,
        { key = tostring(i), mods = mods, action = create_smart_action(tostring(i), mods, act.ActivateTab(i - 1)) }
      )
    end
  end

  for _, mods in ipairs({ "CTRL", "SUPER" }) do
    table.insert(keys, { key = "9", mods = mods, action = create_smart_action("9", mods, act.ActivateTab(-1)) })
  end

  return keys
end

local function get_window_keys()
  local keys = {}
  for _, mods in ipairs({ "CTRL", "SUPER" }) do
    table.insert(keys, { key = "n", mods = mods, action = create_smart_action("n", mods, act.SpawnWindow) })
  end
  return keys
end

local function get_search_keys()
  return {
    { key = "Escape", mods = "CTRL", action = create_smart_action("Escape", "CTRL", act.ActivateCopyMode) },
    {
      key = "/",
      mods = "CTRL",
      action = create_smart_action("/", "CTRL", act.Search("CurrentSelectionOrEmptyString")),
    },
    { key = "f", mods = "CTRL", action = create_smart_action("f", "CTRL", act.PaneSelect) },
  }
end

local function get_scroll_keys()
  return {
    {
      key = "u",
      mods = "CTRL",
      action = create_smart_action("u", "CTRL", { ScrollByLine = -40 }, { passthrough = EDITORS }),
    },
    {
      key = "d",
      mods = "CTRL",
      action = create_smart_action("d", "CTRL", { ScrollByLine = 40 }, { passthrough = EDITORS }),
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
    get_goose_keys(),
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
