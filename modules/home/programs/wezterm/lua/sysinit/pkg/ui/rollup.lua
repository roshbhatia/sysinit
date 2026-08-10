local wezterm = require("wezterm")
local panes_mod = require("sysinit.pkg.ui.panes")

-- `collect` needs a live mux; `reduce` is pure, so the precedence rule is testable.
local M = {}

-- Returns nil if the walk raised.
function M.collect(deck_states)
  local observations = {}
  local ok = pcall(function()
    for _, win in ipairs(wezterm.mux.all_windows()) do
      local workspace = win:get_workspace()
      local window_id = win:window_id()
      for _, tab in ipairs(win:tabs()) do
        local tab_id = tab:tab_id()
        for _, p in ipairs(tab:panes()) do
          local status, reason, since, agent = panes_mod.agent_state(p, deck_states)
          if status then
            local pane_id = p:pane_id()
            local rec = panes_mod.read_pane_record(pane_id)
            observations[#observations + 1] = {
              pane_id = pane_id,
              window_id = window_id,
              tab_id = tab_id,
              workspace = workspace,
              session = rec and rec.session or "",
              repo = (function()
                local r, _ = panes_mod.pane_repo(p)
                return r
              end)(),
              branch = rec and rec.branch or "",
              agent = agent or "",
              status = status,
              reason = reason or "",
              since = since,
              rank = panes_mod.state_rank[status],
            }
          end
        end
      end
    end
  end)
  if not ok then
    return nil
  end
  return observations
end

-- Higher rank wins; on a tie the older `since` wins, and a nil `since` never displaces.
function M.reduce(observations)
  local sessions = {}
  for _, o in ipairs(observations) do
    local rank = panes_mod.state_rank[o.status]
    if rank then
      local cur = sessions[o.workspace]
      if not cur then
        cur = {
          status = o.status,
          reason = o.reason or "",
          since = o.since,
          rank = rank,
          names = {},
        }
        sessions[o.workspace] = cur
      else
        local replace = rank > cur.rank
        if not replace and rank == cur.rank then
          local a, b = o.since, cur.since
          replace = a ~= nil and (b == nil or a < b)
        end
        if replace then
          cur.status, cur.reason, cur.since, cur.rank = o.status, o.reason or "", o.since, rank
        end
      end
      local session = o.session or ""
      if session ~= "" then
        local seen = false
        for _, n in ipairs(cur.names) do
          if n == session then
            seen = true
            break
          end
        end
        if not seen then
          cur.names[#cur.names + 1] = session
        end
      end
    end
  end
  return sessions
end

local cache = { at = -1, sessions = {}, panes = {} }

-- A function, not a table, so the deck is not queried on a cache hit.
function M.states(get_deck_states)
  local now = os.time()
  if now ~= cache.at then
    local observations = M.collect(get_deck_states())
    if observations then
      cache = { at = now, sessions = M.reduce(observations), panes = observations }
    else
      cache = { at = now, sessions = {}, panes = {} }
    end
  end
  return cache.sessions, cache.panes
end

return M
