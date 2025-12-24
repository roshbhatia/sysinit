local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

local function multi_bind(key, modifiers_list, action)
  local bindings = {}
  for _, mods in ipairs(modifiers_list) do
    table.insert(bindings, {
      key = key,
      mods = mods,
      action = action,
    })
  end
  return bindings
end

local function should_passthrough(pane)
  local proc = pane:get_foreground_process_name()
  if not proc then
    return false
  end
  local process_name = string.gsub(proc, "(.*[/\\])(.*)", "%2")
  return process_name == "nvim"
    or process_name == "vim"
    or process_name == "hx"
    or process_name == "k9s"
end

local function should_passthrough_ctrl_w(pane)
  local proc = pane:get_foreground_process_name()
  if not proc then
    return false
  end
  local process_name = string.gsub(proc, "(.*[/\\])(.*)", "%2")
  return process_name == "nvim" or process_name == "vim"
end

local function vim_w_or_wezterm_action(key, mods, wezterm_action)
  return wezterm.action_callback(function(win, pane)
    if should_passthrough_ctrl_w(pane) then
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

    {
      key = "w",
      mods = "CTRL",
      action = vim_w_or_wezterm_action("w", "CTRL", act.CloseCurrentPane({ confirm = true })),
    },
    {
      key = "w",
      mods = "SUPER",
      action = vim_w_or_wezterm_action("w", "SUPER", act.CloseCurrentPane({ confirm = true })),
    },
  }
end

local function get_clear_keys()
  local clear_action = wezterm.action_callback(function(win, pane)
    if should_passthrough(pane) then
      win:perform_action({
        SendKey = {
          key = "k",
          mods = "CTRL",
        },
      }, pane)
    else
      win:perform_action(act.ClearScrollback("ScrollbackAndViewport"), pane)
    end
  end)

  return {
    {
      key = "k",
      mods = "SUPER",
      action = clear_action,
    },
  }
end

local function get_default_keys()
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
    {
      key = "m",
      mods = "SUPER",
      action = act.Hide,
    },
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

local function get_font_keys()
  local keys = {}

  for _, binding in ipairs(multi_bind("-", { "CTRL", "SUPER" }, act.DecreaseFontSize)) do
    table.insert(keys, binding)
  end

  for _, binding in ipairs(multi_bind("=", { "CTRL", "SUPER" }, act.IncreaseFontSize)) do
    table.insert(keys, binding)
  end

  return keys
end

local function get_pallete_keys()
  return {
    {
      key = ";",
      mods = "CTRL|SHIFT",
      action = act.ActivateCommandPalette,
    },
    {
      key = "l",
      mods = "CTRL|SHIFT",
      action = act.ShowDebugOverlay,
    },
  }
end

local function get_window_keys()
  local keys = {}

  for _, binding in ipairs(multi_bind("n", { "CTRL", "SUPER" }, act.SpawnWindow)) do
    table.insert(keys, binding)
  end

  return keys
end

local function get_tab_keys()
  local keys = {}

  for _, binding in ipairs(multi_bind("t", { "CTRL", "SUPER" }, act.SpawnTab("CurrentPaneDomain"))) do
    table.insert(keys, binding)
  end

  table.insert(keys, {
    key = "w",
    mods = "CTRL|SHIFT",
    action = act.CloseCurrentTab({ confirm = true }),
  })

  table.insert(keys, {
    key = "Tab",
    mods = "CTRL",
    action = act.ActivateTabRelative(1),
  })
  table.insert(keys, {
    key = "Tab",
    mods = "CTRL|SHIFT",
    action = act.ActivateTabRelative(-1),
  })

  for i = 1, 8 do
    for _, binding in ipairs(multi_bind(tostring(i), { "CTRL", "SUPER" }, act.ActivateTab(i - 1))) do
      table.insert(keys, binding)
    end
  end

  for _, binding in ipairs(multi_bind("9", { "CTRL", "SUPER" }, act.ActivateTab(-1))) do
    table.insert(keys, binding)
  end

  return keys
end

local function get_search_keys()
  return {
    {
      key = "Escape",
      mods = "CTRL",
      action = act.ActivateCopyMode,
    },
    {
      key = "/",
      mods = "CTRL",
      action = act.Search("CurrentSelectionOrEmptyString"),
    },
    {
      key = "f",
      mods = "CTRL",
      action = act.QuickSelect,
    },
  }
end

local function get_scroll_keys()
  return {
    {
      key = "u",
      mods = "CTRL",
      action = wezterm.action_callback(function(win, pane)
        if should_passthrough(pane) then
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
        if should_passthrough(pane) then
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
        if should_passthrough(pane) then
          win:perform_action({
            SendKey = {
              key = "u",
              mods = "CTRL|SHIFT",
            },
          }, pane)
        else
          win:perform_action(act.ScrollToTop, pane)
        end
      end),
    },
    {
      key = "d",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(function(win, pane)
        if should_passthrough(pane) then
          win:perform_action({
            SendKey = {
              key = "d",
              mods = "CTRL|SHIFT",
            },
          }, pane)
        else
          win:perform_action(act.ScrollToBottom, pane)
        end
      end),
    },
  }
end

local function get_misc_keys()
  return {
    {
      key = "r",
      mods = "CTRL|SHIFT",
      action = act.ReloadConfiguration,
    },
  }
end

local function get_key_tables()
  if not wezterm.gui then
    return {}
  end

  return wezterm.gui.default_key_tables()
end

function M.setup(config)
  config.disable_default_key_bindings = true

  local all_keys = {}

  local key_groups = {
    get_clear_keys(),
    get_default_keys(),
    get_font_keys(),
    get_misc_keys(),
    get_pallete_keys(),
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
  config.key_tables = get_key_tables()
end

return M
