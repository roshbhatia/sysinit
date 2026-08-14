local wezterm = require("wezterm")
local keybindings = require("sysinit.pkg.keybindings")
local utils = require("sysinit.pkg.utils")
local ui_actions = require("sysinit.pkg.ui.actions")
local ui_badges = require("sysinit.pkg.ui.badges")
local ui_format = require("sysinit.pkg.ui.format")
local ui_panes = require("sysinit.pkg.ui.panes")
local ui_sessions = require("sysinit.pkg.ui.sessions")

local M = {}

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
    local sessions, panes = ctx.sessions()
    local now = os.time()

    local agg = {}
    for _, rec in ipairs(panes) do
      local a = agg[rec.workspace]
      if not a then
        a = { count = 0, blocked = 0, repo = "", agent = "", worst_rank = 0, worst_status = nil }
        agg[rec.workspace] = a
      end
      a.count = a.count + 1
      if a.repo == "" and rec.repo ~= "" then
        a.repo = rec.repo
      end
      if rec.rank >= ui_panes.state_rank.working then
        a.blocked = a.blocked + 1
      end
      if rec.rank > a.worst_rank then
        a.worst_rank = rec.rank
        a.worst_status = rec.status
        if rec.agent ~= "" then
          a.agent = rec.agent
        end
      end
    end

    -- Every seshy session this switcher can reach is local, so the tag is fixed
    -- here; it stays present so a row is never silently host-ambiguous.
    local host = ui_format.host_tag(nil)
    local default_choice = { name = "default", path = ctx.home, label = host .. " default" }
    local rows = {}

    for _, name in ipairs(ui_sessions.list_names(ui_sessions.sy_bin)) do
      if name ~= "default" then
        local st = sessions[name]
        local label = host .. " " .. name
        if st then
          local icon = ui_format.state_icons[st.status] or "●"
          label = icon .. " " .. host .. " " .. name
          local a = agg[name]
          if a then
            if a.repo ~= "" then
              label = label .. "  at " .. a.repo
            end
            if a.agent ~= "" then
              label = label .. "  in " .. a.agent
            end
          end
          local age = st.since and ui_format.age(now - st.since) or ""
          local fmt = ui_format.status_label(st.status, st.reason)
          if fmt ~= "" then
            label = label .. "  — " .. fmt
          end
          if age ~= "" then
            label = label .. "  " .. age
          end
        end
        table.insert(rows, {
          name = name,
          path = ui_sessions.seshy_dir .. "/" .. name,
          label = label,
          _rank = st and st.rank or 0,
          _since = st and st.since or nil,
        })
      end
    end

    table.sort(rows, function(a, b)
      if a._rank ~= b._rank then
        return a._rank > b._rank
      end
      if a._rank > 0 and a._since ~= b._since then
        return (a._since or now) < (b._since or now)
      end
      return a.name < b.name
    end)

    local choices = { default_choice }
    for _, row in ipairs(rows) do
      table.insert(choices, { name = row.name, path = row.path, label = row.label })
    end
    return choices
  end

  local function append_host(r, colors, domain)
    if domain == false then
      return
    end
    local tag, is_local = ui_format.host_tag(domain)
    r:append(nil, is_local and colors.chrome or colors.dir_ic, tag)
    r:append(nil, colors.chrome, " ")
  end

  local function attn_row(rec, now, colors)
    local sc = ui_format.status_color(rec.status, colors) or colors.idle
    local icon = ui_format.state_icons[rec.status] or "●"
    local is_urgent = rec.rank and rec.rank >= ui_panes.state_rank.working
    local age = rec.since and ui_format.age(now - rec.since) or ""

    local r = ctx.ribbon.new("attn")
    if is_urgent then
      r:append(nil, colors.waiting, ctx.icons.attn .. " ")
    else
      r:append(nil, nil, "  ")
    end
    r:append(nil, sc, icon .. " ")
    append_host(r, colors, rec.domain)
    local crumb = rec.workspace
    if rec.tab_title ~= "" then
      crumb = crumb .. " · " .. rec.tab_title
    end
    r:append(nil, colors.name, crumb, "Bold")
    local attn_dp = ui_format.smart_path(rec.cwd)
    if attn_dp == "" then
      attn_dp = rec.repo
    end
    if attn_dp ~= "" and attn_dp ~= rec.tab_title then
      r:append(nil, colors.chrome, "  ")
      r:append(nil, colors.age, "at ")
      r:append(nil, colors.name, attn_dp)
    end
    local scope = ui_format.scope_label(rec)
    if scope then
      r:append(nil, colors.chrome, "  ")
      r:append(nil, colors.age, "on ")
      r:append(nil, colors.age, scope)
      if rec.dirty then
        r:append(nil, colors.working, " *")
      end
    end
    if rec.title ~= "" then
      r:append(nil, colors.chrome, "  ")
      r:append(nil, colors.age, "in ")
      if ctx.sigil_ok then
        local proc_items = ctx.sigil.items(rec.title, { fallback = true, padding = "right", reset = true })
        r:append_items(proc_items)
      end
      r:append(nil, colors.name, rec.title)
    end
    local fmt = ui_format.status_label(rec.status, rec.reason)
    if fmt ~= "" then
      r:append(nil, colors.reason, "  " .. fmt)
    end
    if age ~= "" then
      r:append(nil, colors.age, "  " .. age)
    end
    local bc = ui_badges.color(rec.pane_id, colors)
    if bc then
      r:append(nil, colors.chrome, "  ")
      r:append(nil, bc, ui_badges.name(rec.pane_id))
    end
    return r:format()
  end

  local function session_tree_choices(tree, by_id, filter, colors)
    local choices = {}
    local now = os.time()
    local function add(id, label, rec)
      by_id[id] = rec or true
      choices[#choices + 1] = { id = id, label = label }
    end
    filter = filter or "all"

    if filter == "blocked" or filter == "agents" then
      local list = {}
      if filter == "blocked" then
        for _, rec in ipairs(tree.attention) do
          list[#list + 1] = rec
        end
      else
        for _, ws in ipairs(tree.workspaces) do
          for _, tnode in ipairs(ws.tabs) do
            for _, rec in ipairs(tnode.panes) do
              if rec.status then
                list[#list + 1] = rec
              end
            end
          end
        end
        table.sort(list, function(a, b)
          if a.rank ~= b.rank then
            return a.rank > b.rank
          end
          return (a.since or now) < (b.since or now)
        end)
      end
      for _, rec in ipairs(list) do
        add("pane:" .. rec.pane_id, attn_row(rec, now, colors), rec)
      end
      return choices
    end

    if filter == "dormant" then
      for _, ws in ipairs(tree.workspaces) do
        if ws.dormant then
          local r = ctx.ribbon.new("dormant")
          r:append(nil, colors.ws_dorm, ctx.icons.dormant .. " ")
          append_host(r, colors, ws.domain)
          r:append(nil, colors.ws_dorm, ws.name)
          add("ws:" .. ws.name, r:format(), { workspace = ws.name, dormant = true })
        end
      end
      return choices
    end

    if filter == "sessions" then
      local live = {}
      for _, ws in ipairs(tree.workspaces) do
        if not ws.dormant then
          live[#live + 1] = ws
        end
      end
      table.sort(live, function(a, b)
        return (a.last_active or 0) > (b.last_active or 0)
      end)
      for i, ws in ipairs(live) do
        local sc = ui_format.status_color(ws.status, colors)
        local qs = i <= 9 and tostring(i) or string.char(96 + i - 9)
        local r = ctx.ribbon.new("ws")
        r:append(nil, colors.chrome, qs .. "  ")
        r:append(nil, sc or colors.ws_live, ctx.icons.session .. " ")
        append_host(r, colors, ws.domain)
        r:append(nil, colors.name, ws.name, "Bold")
        if ws.status then
          r:append(nil, sc or colors.working, "  " .. (ui_format.state_icons[ws.status] or "●"))
        end
        local age = ws.last_active and ui_format.age(now - ws.last_active) or ""
        if age ~= "" then
          r:append(nil, colors.age, "  " .. age)
        end
        add("ws:" .. ws.name, r:format(), { workspace = ws.name, dormant = false })
      end
      return choices
    end

    local live_sorted = {}
    for _, ws in ipairs(tree.workspaces) do
      if not ws.dormant then
        live_sorted[#live_sorted + 1] = ws
      end
    end
    table.sort(live_sorted, function(a, b)
      return (a.last_active or 0) > (b.last_active or 0)
    end)

    for _, ws in ipairs(live_sorted) do
      local sc = ui_format.status_color(ws.status, colors)
      local ws_r = ctx.ribbon.new("ws")
      ws_r:append(nil, sc or colors.ws_live, ctx.icons.session .. " ")
      append_host(ws_r, colors, ws.domain)
      ws_r:append(nil, colors.name, ws.name, { "Bold", "Single" })
      if ws.status then
        local ws_lbl = ui_format.state_labels[ws.status] or ""
        ws_r:append(nil, colors.chrome, "  ")
        ws_r:append(nil, sc or colors.working, ui_format.state_icons[ws.status] or "●")
        if ws_lbl ~= "" then
          ws_r:append(nil, colors.reason, " " .. ws_lbl)
        end
      end
      add("ws:" .. ws.name, ws_r:format(), { workspace = ws.name, dormant = false })

      for ti, tnode in ipairs(ws.tabs) do
        local tlast = ti == #ws.tabs
        local tbranch = tlast and "  └─ " or "  ├─ "
        local tab_r = ctx.ribbon.new("tab")
        tab_r:append(nil, colors.chrome, tbranch)
        tab_r:append(nil, colors.ws_live, ctx.icons.tab)
        tab_r:append(nil, colors.chrome, " [" .. tostring(ti) .. "]")
        tab_r:append(nil, colors.chrome, "  ")
        append_host(tab_r, colors, tnode.domain)
        tab_r:append(nil, colors.name, tnode.title)
        add(
          "tab:" .. tnode.tab_id,
          tab_r:format(),
          { pane_id = tnode.active_pane_id, workspace = ws.name, tab_index = ti }
        )

        for pi, rec in ipairs(tnode.panes) do
          local pbranch = (tlast and "     " or "  │  ") .. (pi == #tnode.panes and "└─ " or "├─ ")
          local pane_r = ctx.ribbon.new("pane")
          pane_r:append(nil, colors.chrome, pbranch)
          local bc = ui_badges.color(rec.pane_id, colors)
          if bc then
            pane_r:append(nil, colors.chrome, "<")
            pane_r:append(nil, bc, ui_badges.name(rec.pane_id))
            pane_r:append(nil, colors.chrome, "> ")
          end
          append_host(pane_r, colors, rec.domain)
          local pane_dp = ui_format.smart_path(rec.cwd)
          if pane_dp == "" then
            pane_dp = rec.repo
          end
          if pane_dp ~= "" then
            pane_r:append(nil, colors.chrome, "  ")
            pane_r:append(nil, colors.age, "at ")
            pane_r:append(nil, colors.name, pane_dp)
          end
          local pane_scope = ui_format.scope_label(rec)
          if pane_scope then
            pane_r:append(nil, colors.chrome, "  ")
            pane_r:append(nil, colors.age, "on ")
            pane_r:append(nil, colors.age, pane_scope)
            if rec.dirty then
              pane_r:append(nil, colors.working, " *")
            end
          end
          local proc = rec.title ~= "" and rec.title or nil
          if proc then
            pane_r:append(nil, colors.chrome, "  ")
            pane_r:append(nil, colors.age, "in ")
            if ctx.sigil_ok then
              local proc_items = ctx.sigil.items(proc, { fallback = true, padding = "right", reset = true })
              pane_r:append_items(proc_items)
            end
            pane_r:append(nil, colors.name, proc)
          end
          if rec.status then
            local asc = ui_format.status_color(rec.status, colors) or colors.idle
            local p_fmt = ui_format.status_label(rec.status, rec.reason)
            pane_r:append(nil, colors.chrome, "  ")
            pane_r:append(nil, asc, ui_format.state_icons[rec.status] or "●")
            if p_fmt ~= "" then
              pane_r:append(nil, colors.reason, " " .. p_fmt)
            end
            if rec.status ~= "done" then
              local age = rec.since and ui_format.age(now - rec.since) or ""
              if age ~= "" then
                pane_r:append(nil, colors.age, " " .. age)
              end
            end
          end
          add("pane:" .. rec.pane_id, pane_r:format(), rec)
        end
      end
    end

    return choices
  end

  local function session_tree_dispatch(win, pane, id, by_id)
    if not id then
      return
    end
    local rec = by_id[id]
    if type(rec) ~= "table" then
      return
    end
    local kind = id:match("^([^:]+):")
    if kind == "ws" and rec.dormant then
      ui_actions.switch_to_workspace(win, pane, rec.workspace, ui_sessions.seshy_dir .. "/" .. rec.workspace)
    elseif kind == "ws" then
      ui_actions.switch_to_workspace(win, pane, rec.workspace)
    else
      ui_actions.activate_agent_pane(win, pane, rec)
    end
  end

  local tree_state = { pending_filter = nil, pending_action = nil, current_filter = "all", key_table_active = false }
  local function tree_close_key(key)
    return {
      key = key,
      mods = "NONE",
      action = wezterm.action_callback(function(win, pane)
        tree_state.pending_filter = nil
        tree_state.key_table_active = false
        win:perform_action(wezterm.action.PopKeyTable, pane)
        win:perform_action(wezterm.action.SendKey({ key = key }), pane)
      end),
    }
  end
  config.key_tables = config.key_tables or {}
  config.key_tables.session_tree_actions = {
    tree_close_key("Enter"),
    tree_close_key("Escape"),
    {
      key = "d",
      mods = "CTRL",
      action = wezterm.action_callback(function(win, pane)
        tree_state.pending_filter = tree_state.current_filter == "dormant" and "all" or "dormant"
        tree_state.key_table_active = false
        win:perform_action(wezterm.action.PopKeyTable, pane)
        win:perform_action(wezterm.action.SendKey({ key = "Enter" }), pane)
      end),
    },
    {
      key = "x",
      mods = "CTRL",
      action = wezterm.action_callback(function(win, pane)
        tree_state.pending_action = "delete"
        tree_state.key_table_active = false
        win:perform_action(wezterm.action.PopKeyTable, pane)
        win:perform_action(wezterm.action.SendKey({ key = "Enter" }), pane)
      end),
    },
  }

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
    local ok, stdout = wezterm.run_child_process({ wezterm_bin, "cli", "list", "--format=json" })
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
      if wezterm.run_child_process({ wezterm_bin, "cli", "kill-pane", "--pane-id=" .. tostring(pane_id) }) then
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

  local function open_session_tree(win, pane, filter, notice)
    filter = filter or "all"
    tree_state.current_filter = filter
    local tree = ctx.tree()
    local colors = ctx.colors(win)
    local by_id = {}
    local choices = session_tree_choices(tree, by_id, filter, colors)
    if #choices == 0 then
      if filter and filter ~= "all" then
        filter, by_id = "all", {}
        choices = session_tree_choices(tree, by_id, "all", colors)
      end
      if #choices == 0 then
        return
      end
    end
    local title
    if filter == "dormant" then
      title = "Sessions  [dormant · ^d all · ^x close]"
    else
      title = "Sessions  [^d dormant · ^x close]"
    end
    if notice then
      title = title .. "  · " .. notice
    end
    tree_state.pending_filter = nil
    tree_state.key_table_active = true
    win:perform_action(wezterm.action.ActivateKeyTable({ name = "session_tree_actions", one_shot = false }), pane)
    win:perform_action(
      wezterm.action.InputSelector({
        title = title,
        choices = choices,
        fuzzy = false,
        description = "  j/k nav  1-9 jump  / filter  ^d dormant  ^x close  Esc quit",
        fuzzy_description = "  filter (Esc to leave):  ",
        action = wezterm.action_callback(function(inner_win, inner_pane, id, _label)
          if tree_state.key_table_active then
            tree_state.key_table_active = false
            inner_win:perform_action(wezterm.action.PopKeyTable, inner_pane)
          end
          local pa = tree_state.pending_action
          tree_state.pending_action = nil
          local pf = tree_state.pending_filter
          tree_state.pending_filter = nil
          if pa == "delete" and id then
            local close_notice, reopen = close_session_target(inner_win, inner_pane, id, by_id)
            if reopen then
              wezterm.time.call_after(0.15, function()
                open_session_tree(inner_win, inner_pane, tree_state.current_filter, close_notice)
              end)
            end
            return
          end
          if pf then
            wezterm.time.call_after(0.05, function()
              open_session_tree(inner_win, inner_pane, pf)
            end)
            return
          end
          session_tree_dispatch(inner_win, inner_pane, id, by_id)
        end),
      }),
      pane
    )
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

  for _, cycle in ipairs({
    { key = "]", step = wm.next_workspace },
    { key = "[", step = wm.previous_workspace },
  }) do
    local step = type(cycle.step) == "function" and cycle.step() or nil
    if step then
      table.insert(config.keys, {
        key = cycle.key,
        mods = "CTRL",
        action = wezterm.action_callback(function(win, pane)
          if keybindings.locked_mode then
            win:perform_action({ SendKey = { key = cycle.key, mods = "CTRL" } }, pane)
            return
          end
          win:perform_action(step, pane)
        end),
      })
    else
      wezterm.log_warn("workspace-manager has no " .. cycle.key .. " cycle action; CTRL-" .. cycle.key .. " unbound")
    end
  end

  wezterm.on("augment-command-palette", function(_window, _pane)
    return {
      {
        brief = "Session tree",
        action = wezterm.action_callback(function(win, pane)
          open_session_tree(win, pane)
        end),
      },
      {
        brief = "Switch seshy session / workspace",
        action = wm.workspace_switcher(),
      },
      {
        brief = "Switch to previous workspace",
        action = wm.switch_to_previous_workspace(),
      },
      {
        brief = "Next workspace",
        action = wezterm.action.SwitchWorkspaceRelative(1),
      },
      {
        brief = "Previous workspace",
        action = wezterm.action.SwitchWorkspaceRelative(-1),
      },
    }
  end)
end

return M
