local wezterm = require("wezterm")
local keybindings = require("sysinit.pkg.keybindings")
local utils = require("sysinit.pkg.utils")
local ui_actions = require("sysinit.pkg.ui.actions")
local ui_badges = require("sysinit.pkg.ui.badges")
local ui_panes = require("sysinit.pkg.ui.panes")
local ui_sessions = require("sysinit.pkg.ui.sessions")
local launcher = require("sysinit.pkg.ui.launcher")

local M = {}

local SESSION_SELECTOR_ALPHABET = "1234567890abcdefghilmnopqrstuvwyzABCDEFGHILMNOPQRSTUVWYZ"
local SESSION_TREE_ACTIONS = {
  { id = "open-directory", key = ".", hint = "directory" },
  { id = "close-target", key = "x", hint = "close" },
}
local SESSION_SELECTOR_HELP = {
  { key = "j/k", hint = "nav" },
  {
    key = "Enter",
    hint = function(verb)
      return verb
    end,
  },
  { key = "/", hint = "filter" },
  { key = "Esc", hint = "quit" },
}

local function session_help(verb, actions)
  local bindings = { SESSION_SELECTOR_HELP[1], SESSION_SELECTOR_HELP[2] }
  for _, action in ipairs(actions or {}) do
    bindings[#bindings + 1] = action
  end
  for index = 3, #SESSION_SELECTOR_HELP do
    bindings[#bindings + 1] = SESSION_SELECTOR_HELP[index]
  end

  local parts = {}
  for _, binding in ipairs(bindings) do
    local hint = type(binding.hint) == "function" and binding.hint(verb) or binding.hint
    parts[#parts + 1] = binding.key .. " " .. hint
  end
  return "  " .. table.concat(parts, "  ")
end

---@param choices table
---@param verb string
---@return table
function M.session_selector_options(choices, verb)
  -- InputSelector assigns every custom key to a visible choice. It cannot
  -- register hidden actions, so each selector contains session targets only.
  return {
    choices = choices,
    alphabet = SESSION_SELECTOR_ALPHABET,
    fuzzy = false,
    description = session_help(verb),
  }
end

function M.session_tree_description()
  return session_help("open", SESSION_TREE_ACTIONS)
end

---@param opts table
---@return table
function M.close_plan(opts)
  local targets, self_targeted, here_panes, here_targets = {}, false, 0, 0
  for _, p in ipairs(opts.panes or {}) do
    local hit = opts.match(p) and true or false
    if opts.here ~= nil and p.workspace == opts.here then
      here_panes = here_panes + 1
      if hit then
        here_targets = here_targets + 1
      end
    end
    if hit then
      if p.pane_id == opts.self_pane_id then
        self_targeted = true
      end
      targets[#targets + 1] = p.pane_id
    end
  end
  if #targets == 0 then
    return { targets = {}, label = opts.label, refusal = "nothing open in " .. opts.label }
  end

  local empties_here = opts.here ~= nil and here_targets > 0 and here_targets == here_panes
  local resetting = opts.target_workspace ~= nil and opts.target_workspace == opts.fallback
  if resetting then
    local keep = self_targeted and opts.self_pane_id or targets[1]
    local kept = {}
    for _, pane_id in ipairs(targets) do
      if pane_id ~= keep then
        kept[#kept + 1] = pane_id
      end
    end
    if #kept == 0 then
      return { targets = {}, label = opts.fallback, refusal = opts.fallback .. " is already one pane" }
    end
    return {
      targets = kept,
      label = opts.fallback,
      verb = "reset",
      reopen = true,
    }
  end

  return {
    targets = targets,
    label = opts.label,
    verb = "closed",
    switch_to = empties_here and opts.fallback or nil,
    reopen = not self_targeted and not empties_here,
  }
end

function M.setup(config, wm, ctx)
  wm.get_choices = function()
    local choices = {}
    for _, name in ipairs(ui_sessions.active_names()) do
      choices[#choices + 1] = { name = name, label = name }
    end
    return choices
  end

  local session_tree_choices = require("sysinit.pkg.ui.tree_rows").new(ctx)

  local function session_tree_dispatch(win, pane, id, by_id)
    if not id then
      return
    end
    local rec = by_id[id]
    if type(rec) ~= "table" then
      return
    end
    local kind = id:match("^([^:]+):")
    if kind == "ws" then
      ui_actions.switch_to_workspace(win, pane, rec.workspace)
    else
      ui_actions.activate_agent_pane(win, pane, rec)
    end
  end

  local function close_session_target(win, pane, id, by_id)
    local rec = by_id[id]
    if type(rec) ~= "table" then
      return "nothing to close", true
    end
    local kind = id:match("^([^:]+):")
    local match, label
    if kind == "ws" then
      local name = rec.workspace
      match = function(p)
        return p.workspace == name
      end
      label = "session " .. name
    elseif kind == "tab" then
      local tab_id = tonumber(id:match("^tab:(.+)$"))
      if not tab_id then
        return "not a closable row", true
      end
      match = function(p)
        return p.tab_id == tab_id
      end
      label = "tab " .. tostring(rec.tab_index or tab_id)
    elseif kind == "pane" then
      local pane_id = rec.pane_id
      match = function(p)
        return p.pane_id == pane_id
      end
      label = "pane " .. ui_badges.name(pane_id)
    else
      return "not a closable row", true
    end

    local self_pane_id
    pcall(function()
      self_pane_id = pane:pane_id()
    end)
    local here
    pcall(function()
      here = win:active_workspace()
    end)

    local wezterm_bin = (wezterm.executable_dir or "") .. "/wezterm"
    local ok, stdout = wezterm.run_child_process({ wezterm_bin, "cli", "--no-auto-start", "list", "--format=json" })
    if not ok then
      wezterm.log_error("wezterm cli list failed; " .. label .. " left open")
      return "close failed: " .. label, true
    end

    local plan = M.close_plan({
      panes = wezterm.json_parse(stdout) or {},
      match = match,
      label = label,
      here = here,
      self_pane_id = self_pane_id,
      fallback = "default",
      target_workspace = kind == "ws" and rec.workspace or nil,
    })
    if plan.refusal then
      return plan.refusal, true
    end
    if plan.switch_to then
      ui_actions.switch_to_workspace(win, pane, plan.switch_to)
    end

    local killed = 0
    for _, pane_id in ipairs(plan.targets) do
      if
        wezterm.run_child_process({
          wezterm_bin,
          "cli",
          "--no-auto-start",
          "kill-pane",
          "--pane-id=" .. tostring(pane_id),
        })
      then
        killed = killed + 1
      end
    end
    if killed == 0 then
      return "close failed: " .. plan.label, plan.reopen
    end
    if killed == #plan.targets then
      return string.format("%s %s (%d pane%s)", plan.verb, plan.label, killed, killed == 1 and "" or "s"), plan.reopen
    end
    return string.format("%s %d of %d panes in %s", plan.verb, killed, #plan.targets, plan.label), plan.reopen
  end

  local open_session_tree
  local tree_pending_actions = {}

  local function tree_window_id(win)
    local ok, id = pcall(function()
      return win:window_id()
    end)
    return ok and tostring(id) or tostring(win)
  end

  local function finish_session_tree_action(win, pane, action, key)
    tree_pending_actions[tree_window_id(win)] = action or false
    win:perform_action(wezterm.action.PopKeyTable, pane)
    win:perform_action(wezterm.action.SendKey({ key = key or "Enter" }), pane)
  end

  config.key_tables = config.key_tables or {}
  config.key_tables.sysinit_session_tree = {
    {
      key = "Enter",
      mods = "NONE",
      action = wezterm.action_callback(function(win, pane)
        finish_session_tree_action(win, pane, nil)
      end),
    },
    {
      key = "Escape",
      mods = "NONE",
      action = wezterm.action_callback(function(win, pane)
        finish_session_tree_action(win, pane, nil, "Escape")
      end),
    },
    {
      key = "/",
      mods = "NONE",
      action = wezterm.action_callback(function(win, pane)
        finish_session_tree_action(win, pane, nil, "/")
      end),
    },
  }
  for _, spec in ipairs(SESSION_TREE_ACTIONS) do
    config.key_tables.sysinit_session_tree[#config.key_tables.sysinit_session_tree + 1] = {
      key = spec.key,
      mods = "NONE",
      action = wezterm.action_callback(function(win, pane)
        finish_session_tree_action(win, pane, spec.id)
      end),
    }
  end

  local function open_close_selector(win, pane, notice)
    local tree = ctx.tree()
    local colors = ctx.colors(win)
    local by_id = {}
    local choices = session_tree_choices(tree, by_id, "all", colors)
    local close_choices = {}
    for _, choice in ipairs(choices) do
      if not choice.id:match("^section:") and not choice.id:match("^group:") then
        close_choices[#close_choices + 1] = choice
      end
    end
    if #close_choices == 0 then
      return
    end
    local options = M.session_selector_options(close_choices, "close")
    options.title = "Close session target"
    if notice then
      options.title = options.title .. "  · " .. notice
    end
    options.action = wezterm.action_callback(function(close_win, close_pane, close_id, _close_label)
      if not close_id then
        return
      end
      local close_notice, reopen = close_session_target(close_win, close_pane, close_id, by_id)
      if reopen then
        wezterm.time.call_after(0.15, function()
          open_close_selector(close_win, close_pane, close_notice)
        end)
      end
    end)
    win:perform_action(wezterm.action.InputSelector(options), pane)
  end

  open_session_tree = function(win, pane, filter, notice)
    filter = filter or "all"
    local tree = ctx.tree()
    local colors = ctx.colors(win)
    local by_id = {}
    local target_choices = session_tree_choices(tree, by_id, filter, colors)
    if #target_choices == 0 then
      if filter and filter ~= "all" then
        filter, by_id = "all", {}
        target_choices = session_tree_choices(tree, by_id, "all", colors)
      end
      if #target_choices == 0 then
        return
      end
    end
    local options = M.session_selector_options(target_choices, "open")
    options.description = M.session_tree_description()
    local title = "Sessions"
    if notice then
      title = title .. "  · " .. notice
    end
    options.title = title
    options.action = wezterm.action_callback(function(inner_win, inner_pane, id, _label)
      local window_id = tree_window_id(inner_win)
      local pending = tree_pending_actions[window_id]
      tree_pending_actions[window_id] = nil
      pcall(function()
        if inner_win:active_key_table() == "sysinit_session_tree" then
          inner_win:perform_action(wezterm.action.PopKeyTable, inner_pane)
        end
      end)
      if pending == "open-directory" then
        wezterm.time.call_after(0.05, function()
          launcher.open_directory(inner_win, inner_pane)
        end)
        return
      end
      if pending == "close-target" then
        if not id then
          return
        end
        local close_notice, reopen = close_session_target(inner_win, inner_pane, id, by_id)
        if reopen then
          wezterm.time.call_after(0.15, function()
            open_session_tree(inner_win, inner_pane, filter, close_notice)
          end)
        end
        return
      end
      session_tree_dispatch(inner_win, inner_pane, id, by_id)
    end)
    tree_pending_actions[tree_window_id(win)] = nil
    win:perform_action(wezterm.action.ActivateKeyTable({ name = "sysinit_session_tree", one_shot = false }), pane)
    win:perform_action(wezterm.action.InputSelector(options), pane)
  end

  wm.session_enabled = true
  wm.session_restore_on_startup = false
  wm.session_state_dir = utils.state_path("weztermWorkspaceState", "wezterm/workspace_state")
  wm.workspace_switcher_sort = "recency"

  wm.apply_to_config(config)
  local wm_injected_keys = {
    { key = "s", mods = "LEADER" },
    { key = "S", mods = "LEADER" },
    { key = "]", mods = "CTRL" },
    { key = "[", mods = "CTRL" },
  }
  if config.keys then
    for _, injected in ipairs(wm_injected_keys) do
      for i = #config.keys, 1, -1 do
        local k = config.keys[i]
        if k.key == injected.key and k.mods == injected.mods then
          table.remove(config.keys, i)
        end
      end
    end
  end

  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = "s",
    mods = "SUPER",
    action = wezterm.action_callback(function(win, pane)
      if keybindings.locked_mode then
        win:perform_action({ SendKey = { key = "s", mods = "SUPER" } }, pane)
        return
      end
      open_session_tree(win, pane)
    end),
  })

  -- Nothing rebinds CTRL-[ or CTRL-]. CTRL-[ is the escape character, so a
  -- binding on it takes Escape away from vim, readline and every other TUI.
  -- The wm_injected_keys removal above is what frees it. Session stepping is
  -- [ and ] inside the session tree, and the command palette still carries the
  -- recency and relative workspace actions.

  wezterm.on("augment-command-palette", function(_window, _pane)
    return {
      {
        brief = "Session tree",
        action = wezterm.action_callback(function(win, pane)
          open_session_tree(win, pane)
        end),
      },
      {
        brief = "Open directory group",
        action = wezterm.action_callback(function(win, pane)
          launcher.open_directory(win, pane)
        end),
      },
      {
        brief = "Connect to host",
        action = wezterm.action_callback(function(win, pane)
          launcher.connect_host(win, pane, config.ssh_domains or {})
        end),
      },
      {
        brief = "Session: close target",
        action = wezterm.action_callback(function(win, pane)
          open_close_selector(win, pane)
        end),
      },
      {
        brief = "Session: step forward",
        action = wezterm.action_callback(function(win, pane)
          ui_actions.step_session(win, pane, 1)
        end),
      },
      {
        brief = "Session: step back",
        action = wezterm.action_callback(function(win, pane)
          ui_actions.step_session(win, pane, -1)
        end),
      },
      {
        brief = "Session: last visited",
        action = wm.switch_to_previous_workspace(),
      },
    }
  end)
end

return M
