local wezterm = require("wezterm")
local ui_format = require("sysinit.pkg.ui.format")
local ui_panes = require("sysinit.pkg.ui.panes")
local ui_sessions = require("sysinit.pkg.ui.sessions")

local M = {}

function M.build(deck_states)
  local workspaces = {}
  local ws_index = {}
  local attention = {}

  pcall(function()
    for _, win in ipairs(wezterm.mux.all_windows()) do
      local workspace = win:get_workspace()
      local window_id = win:window_id()
      local ws = ws_index[workspace]
      if not ws then
        ws = {
          name = workspace,
          dormant = false,
          rank = 0,
          since = nil,
          last_active = ui_sessions.last_active(workspace),
          status = nil,
          tabs = {},
        }
        ws_index[workspace] = ws
        workspaces[#workspaces + 1] = ws
      end
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
          title = ui_format.tab_label(tab, ti, resolved_active),
          active_pane_id = resolved_active and resolved_active:pane_id() or nil,
          panes = {},
        }
        for _, info in ipairs(infos) do
          local p = info.pane
          local status, reason, since, agent = ui_panes.agent_state(p, deck_states)
          local rank = status and ui_panes.state_rank[status] or 0
          local pid = p:pane_id()
          local repo, cwd = ui_panes.pane_repo(p)
          local git = ui_panes.read_pane_record(pid)
          local rec = {
            pane_id = pid,
            window_id = window_id,
            tab_id = tnode.tab_id,
            workspace = workspace,
            tab_title = tnode.title,
            repo = repo,
            cwd = cwd,
            branch = git and git.branch or nil,
            dirty = git and git.dirty or false,
            title = ui_format.pane_proc(p, agent),
            agent = agent or "",
            status = status,
            reason = reason or "",
            since = since,
            rank = rank,
          }
          tnode.panes[#tnode.panes + 1] = rec
          if since and (not ws.last_active or since > ws.last_active) then
            ws.last_active = since
          end
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
      local ws = { name = name, dormant = true, rank = 0, since = nil, status = nil, tabs = {} }
      ws_index[name] = ws
      workspaces[#workspaces + 1] = ws
    end
  end

  local now = os.time()
  table.sort(attention, function(a, b)
    if a.rank ~= b.rank then
      return a.rank > b.rank
    end
    return (a.since or now) < (b.since or now)
  end)

  return { workspaces = workspaces, attention = attention }
end

function M.colors(win, config_data)
  local ok, pal = pcall(function()
    return win:effective_config().resolved_palette
  end)
  pal = (ok and pal) or (config_data and config_data.colors) or {}
  local a, b = pal.ansi or {}, pal.brights or {}
  return {
    ws_live  = b[7] or b[8] or pal.foreground or "#c0caf5",   -- bright cyan/white — live session
    ws_dorm  = a[8] or pal.foreground or "#a9b1d6",           -- ansi-white (mid-gray) — dormant
    dir_ic   = a[5] or "#7aa2f7",                             -- ansi blue — folder icon (softer than bright)
    waiting  = b[2] or a[2] or "#f7768e",                     -- bright red — needs input (status signal: keep vivid)
    done     = b[3] or a[3] or "#9ece6a",                     -- bright green — finished (status signal: keep vivid)
    working  = b[4] or a[4] or "#e0af68",                     -- bright yellow — running (status signal: keep vivid)
    idle     = a[8] or "#a9b1d6",                             -- ansi-white (mid-gray) — idle
    name     = pal.foreground or "#c0caf5",
    reason   = a[6] or "#bb9af7",                             -- ansi magenta — muted; reason is secondary info
    age      = a[8] or "#a9b1d6",                             -- ansi-white (mid-gray) — timestamps
    chrome   = b[1] or "#414868",                             -- bright-black — intentionally dim tree lines
    badge_bg = pal.cursor_bg or b[1] or "#414868",            -- subtle chip background for pane badges
    ghost    = a[8] or pal.foreground or "#a9b1d6",            -- muted bracketed match suffix
    ansi     = a,                                              -- raw ansi array for badge color slots
    brights  = b,
  }
end


return M
