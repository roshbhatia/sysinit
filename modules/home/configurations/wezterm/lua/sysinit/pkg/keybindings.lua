local wezterm = require("wezterm")
local act = wezterm.action
local utils = require("sysinit.pkg.utils")

local M = {}

M.locked_mode = false

-- Constants
local EDITORS = { "nvim", "vim", "hx" }
local COMMON_MODS = { "CTRL", "SUPER" }

-- Helper: Check if current process is goose
local function is_goose(pane)
  return utils.get_process_name(pane) == "goose"
end

-- Create a smart keybind that respects locked mode and passthrough processes
local function create_smart_keybind(key, mods, wezterm_action, opts)
  return {
    key = key,
    mods = mods,
    action = wezterm.action_callback(function(win, pane)
      if M.locked_mode then
        win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
        return
      end

      if opts and opts.passthrough then
        local proc = utils.get_process_name(pane)
        for _, p in ipairs(opts.passthrough) do
          if proc == p then
            win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
            return
          end
        end
      end

      win:perform_action(wezterm_action, pane)
    end),
  }
end

-- Helper: Create multiple bindings for the same key with different modifiers
local function create_multi_mod_bindings(key, action_fn, mod_list)
  local bindings = {}
  for _, mods in ipairs(mod_list or COMMON_MODS) do
    table.insert(bindings, create_smart_keybind(key, mods, action_fn(mods)))
  end
  return bindings
end

local function get_goose_keys()
  return {
    {
      key = "Enter",
      mods = "SHIFT",
      action = wezterm.action_callback(function(win, pane)
        if not M.locked_mode and is_goose(pane) then
          win:perform_action({ SendKey = { key = "j", mods = "CTRL" } }, pane)
        end
      end),
    },
  }
end

local function get_pane_keys()
  local DIRECTION_KEYS = { h = "Left", j = "Down", k = "Up", l = "Right" }
  local keys = {
    create_smart_keybind("s", "CTRL", act.SplitVertical({ domain = "CurrentPaneDomain" })),
    create_smart_keybind("v", "CTRL", act.SplitHorizontal({ domain = "CurrentPaneDomain" })),
    create_smart_keybind("m", "CTRL", act.TogglePaneZoomState),
  }

  -- Navigation and resize for h, j, k, l
  for _, key in ipairs({ "h", "j", "k", "l" }) do
    local dir = DIRECTION_KEYS[key]
    table.insert(keys, create_smart_keybind(key, "CTRL", { ActivatePaneDirection = dir }, { passthrough = EDITORS }))
    table.insert(
      keys,
      create_smart_keybind(key, "CTRL|SHIFT", { AdjustPaneSize = { dir, 3 } }, { passthrough = EDITORS })
    )
  end

  -- Close pane with CTRL/SUPER
  for _, binding in
    ipairs(create_multi_mod_bindings("w", function()
      return act.CloseCurrentPane({ confirm = true })
    end))
  do
    table.insert(keys, binding)
  end

  return keys
end

local function get_system_keys()
  return {
    create_smart_keybind(":", "CTRL", act.ActivateCommandPalette),
    create_smart_keybind(":", "CTRL|SHIFT", act.ShowDebugOverlay),
    create_smart_keybind("c", "SUPER", act.CopyTo("Clipboard")),
    create_smart_keybind("h", "SUPER", act.HideApplication),
    create_smart_keybind("k", "SUPER", act.ClearScrollback("ScrollbackAndViewport")),
    create_smart_keybind("m", "SUPER", act.Hide),
    create_smart_keybind("q", "SUPER", act.QuitApplication),
    create_smart_keybind("v", "SUPER", act.PasteFrom("Clipboard")),
  }
end

local function get_font_keys()
  local keys = {}
  for _, binding in
    ipairs(create_multi_mod_bindings("-", function()
      return act.DecreaseFontSize
    end))
  do
    table.insert(keys, binding)
  end
  for _, binding in
    ipairs(create_multi_mod_bindings("=", function()
      return act.IncreaseFontSize
    end))
  do
    table.insert(keys, binding)
  end
  return keys
end

local function get_tab_keys()
  local keys = {
    create_smart_keybind("w", "CTRL|SHIFT", act.CloseCurrentTab({ confirm = true })),
    create_smart_keybind("Tab", "CTRL", act.ActivateTabRelative(1)),
    create_smart_keybind("Tab", "CTRL|SHIFT", act.ActivateTabRelative(-1)),
    create_smart_keybind("o", "CTRL|SHIFT", act.ActivateLastTab),
  }

  -- New tab with CTRL/SUPER
  for _, binding in
    ipairs(create_multi_mod_bindings("t", function()
      return act.SpawnTab("CurrentPaneDomain")
    end))
  do
    table.insert(keys, binding)
  end

  -- Tab switching: 1-8 go to specific tabs, 9 goes to last tab
  for i = 1, 9 do
    local tab_action = i == 9 and act.ActivateTab(-1) or act.ActivateTab(i - 1)
    for _, binding in
      ipairs(create_multi_mod_bindings(tostring(i), function()
        return tab_action
      end))
    do
      table.insert(keys, binding)
    end
  end

  return keys
end

local function get_window_keys()
  return {
    create_smart_keybind("n", "SUPER", act.SpawnWindow),
  }
end

local function get_search_keys()
  return {
    create_smart_keybind("Escape", "CTRL", act.ActivateCopyMode),
    create_smart_keybind("/", "CTRL", act.Search("CurrentSelectionOrEmptyString")),
    create_smart_keybind("f", "CTRL", act.PaneSelect),
  }
end

local function get_scroll_keys()
  return {
    create_smart_keybind("u", "CTRL", { ScrollByLine = -40 }, { passthrough = EDITORS }),
    create_smart_keybind("d", "CTRL", { ScrollByLine = 40 }, { passthrough = EDITORS }),
  }
end

-- Merge all key groups into a single table
local function merge_keys(...)
  local result = {}
  for _, group in ipairs({ ... }) do
    for _, key in ipairs(group) do
      table.insert(result, key)
    end
  end
  return result
end

function M.setup(config)
  config.disable_default_key_bindings = true

  -- Collect all keybindings
  local keys = merge_keys(
    get_system_keys(),
    get_font_keys(),
    get_pane_keys(),
    get_scroll_keys(),
    get_search_keys(),
    get_tab_keys(),
    get_window_keys(),
    get_goose_keys()
  )

  -- Add locked mode toggle
  table.insert(keys, {
    key = "g",
    mods = "CTRL",
    action = wezterm.action_callback(function()
      M.locked_mode = not M.locked_mode
    end),
  })

  config.keys = keys
  config.key_tables = wezterm.gui and wezterm.gui.default_key_tables() or {}
  config.mouse_bindings = {
    {
      event = { Down = { streak = 3, button = "Left" } },
      action = act.SelectTextAtMouseCursor("SemanticZone"),
      mods = "NONE",
    },
  }
end

return M
