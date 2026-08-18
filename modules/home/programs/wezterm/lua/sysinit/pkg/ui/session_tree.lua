local wezterm = require("wezterm")
local ui_format = require("sysinit.pkg.ui.format")
local ui_panes = require("sysinit.pkg.ui.panes")
local ui_sessions = require("sysinit.pkg.ui.sessions")

local M = {}

-- nil is "no pane seen yet", false is "panes disagree", so a tab or workspace
-- claims a host only when every pane under it is on that one host.
local function merge_domain(current, domain)
  if current == nil then
    return domain
  end
  if current == false or current ~= domain then
    return false
  end
  return current
end

function M.build(deck_states)
  local workspaces = {}
  local ws_index = {}
  local attention = {}
  local remote = ui_sessions.remote_cached()

  pcall(function()
    for _, win in ipairs(wezterm.mux.all_windows()) do
      local workspace = win:get_workspace()
      local window_id = win:window_id()
      local ws = ws_index[workspace]
      if not ws then
        local _, bare = ui_sessions.split(workspace, remote)
        ws = {
          name = workspace,
          display_name = bare,
          dormant = false,
          rank = 0,
          since = nil,
          -- Only real focus counts. Folding an agent's `since` in here made a
          -- workspace you never visited outrank the one you just left.
          last_active = ui_sessions.last_active(workspace),
          status = nil,
          tabs = {},
        }
        ws_index[workspace] = ws
        workspaces[#workspaces + 1] = ws
      end
      -- Two mux windows can share one workspace, and each numbers its own tabs
      -- from 1. Carrying the window ordinal keeps the tree's [n] the same n that
      -- ActivateTab uses instead of a position in the flattened list.
      ws.window_ids = ws.window_ids or {}
      if not ws.window_ids[window_id] then
        ws.window_count = (ws.window_count or 0) + 1
        ws.window_ids[window_id] = ws.window_count
      end
      local window_index = ws.window_ids[window_id]
      for ti, tab in ipairs(win:tabs()) do
        local infos = tab:panes_with_info()
        local active_pane
        for _, info in ipairs(infos) do
          if info.is_active then
            active_pane = info.pane
          end
        end
        local resolved_active = active_pane or (infos[1] and infos[1].pane)
        local tnode = {
          tab_id = tab:tab_id(),
          index = ti,
          window_id = window_id,
          window_index = window_index,
          title = ui_format.tab_label(tab, ti, resolved_active),
          active_pane_id = resolved_active and resolved_active:pane_id() or nil,
          panes = {},
        }
        for _, info in ipairs(infos) do
          local p = info.pane
          local pid = p:pane_id()
          local git = ui_panes.read_pane_record(pid)
          local status, reason, since, agent = ui_panes.agent_state(p, deck_states, git or false)
          local rank = status and ui_panes.state_rank[status] or 0
          local repo, cwd = ui_panes.pane_repo(p)
          local domain = ui_panes.pane_domain(p)
          tnode.domain = merge_domain(tnode.domain, domain)
          ws.domain = merge_domain(ws.domain, domain)
          local rec = {
            pane_id = pid,
            window_id = window_id,
            tab_id = tnode.tab_id,
            workspace = workspace,
            domain = domain,
            tab_title = tnode.title,
            repo = repo,
            cwd = cwd,
            branch = git and git.branch or nil,
            repo_count = git and git.repo_count or 0,
            dirty = git and git.dirty or false,
            title = ui_format.pane_proc(p, agent),
            agent = agent or "",
            status = status,
            reason = reason or "",
            since = since,
            rank = rank,
          }
          tnode.panes[#tnode.panes + 1] = rec
          if rank >= ui_panes.state_rank.working then
            attention[#attention + 1] = rec
            if rank > ws.rank or (rank == ws.rank and since and (not ws.since or since < ws.since)) then
              ws.rank, ws.since, ws.status = rank, since, status
            end
          end
        end
        ws.tabs[#ws.tabs + 1] = tnode
      end
    end
  end)

  for _, name in ipairs(ui_sessions.names_cached()) do
    if not ws_index[name] then
      local ws = { name = name, display_name = name, dormant = true, rank = 0, since = nil, status = nil, tabs = {} }
      ws_index[name] = ws
      workspaces[#workspaces + 1] = ws
    end
  end

  -- A remote session is host-qualified so WezTerm's flat workspace namespace
  -- cannot merge `foo` on two hosts into one workspace.
  local unreachable = {}
  for _, entry in ipairs(remote) do
    if entry.ok then
      for _, session in ipairs(entry.sessions) do
        local name = ui_sessions.qualify(entry.host, session.name)
        if type(session.name) == "string" and session.name ~= "" and not ws_index[name] then
          local ws = {
            name = name,
            display_name = session.name,
            dormant = true,
            domain = entry.domain,
            rank = 0,
            since = nil,
            status = nil,
            tabs = {},
          }
          ws_index[name] = ws
          workspaces[#workspaces + 1] = ws
        end
      end
    else
      unreachable[#unreachable + 1] = {
        host = entry.host,
        domain = entry.domain,
        reason = entry.reason or "unavailable",
      }
    end
  end

  local now = os.time()
  table.sort(attention, function(a, b)
    if a.rank ~= b.rank then
      return a.rank > b.rank
    end
    return (a.since or now) < (b.since or now)
  end)

  return { workspaces = workspaces, attention = attention, unreachable = unreachable }
end

function M.colors(win, config_data)
  local ok, pal = pcall(function()
    return win:effective_config().resolved_palette
  end)
  pal = (ok and pal) or (config_data and config_data.colors) or {}
  local a, b = pal.ansi or {}, pal.brights or {}
  return {
    ws_live = b[7] or b[8] or pal.foreground or "#c0caf5",
    ws_dorm = a[8] or pal.foreground or "#a9b1d6",
    dir_ic = a[5] or "#7aa2f7",
    waiting = b[2] or a[2] or "#f7768e",
    done = b[3] or a[3] or "#9ece6a",
    working = b[4] or a[4] or "#e0af68",
    idle = a[8] or "#a9b1d6",
    name = pal.foreground or "#c0caf5",
    reason = a[6] or "#bb9af7",
    age = a[8] or "#a9b1d6",
    chrome = b[1] or "#414868",
    badge_bg = pal.cursor_bg or b[1] or "#414868",
    ghost = a[8] or pal.foreground or "#a9b1d6",
    ansi = a,
    brights = b,
  }
end

return M
