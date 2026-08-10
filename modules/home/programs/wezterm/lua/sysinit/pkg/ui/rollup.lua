local wezterm = require("wezterm")
local panes_mod = require("sysinit.pkg.ui.panes")

-- Collapses every agent pane in the mux to one entry per workspace, and caches
-- the result for a second.
--
-- The walk and the collapse are separate on purpose. `collect` needs a live
-- mux and cannot run under test; `reduce` is a pure function of `collect`'s
-- output and is where the precedence rule lives, so a test can exercise the
-- rule without a GUI.
local M = {}

-- Walks the mux and returns one observation per agent pane, in walk order.
-- Returns nil if the walk raised, which is what the pcall in the original
-- `compute_agent_session_states` did before it returned two empty tables.
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
            -- The record read costs one file open per agent pane. Only panes
            -- with a status reach here, and the cache below throttles the whole
            -- function to once a second, which is what `session_tree` relies on
            -- for the same read.
            local rec = panes_mod.read_pane_record(pane_id)
            observations[#observations + 1] = {
              pane_id = pane_id,
              window_id = window_id,
              tab_id = tab_id,
              workspace = workspace,
              -- The workspace is the group; the session is what is inside it.
              -- The two are different namespaces and neither replaces the other.
              session = rec and rec.session or "",
              repo = (function() local r, _ = panes_mod.pane_repo(p); return r end)(),
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

-- Collapses observations to one entry per workspace. Pure: same input, same
-- output, no mux and no filesystem.
--
-- Precedence: the higher rank wins, and on a tie the older `since` wins. A
-- pane with no `since` never displaces one that has it.
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
          -- The session names of the panes in this group, first seen first. It
          -- lives on the collapsed entry and not on the observation list alone,
          -- because two of the three consumers take the first return only and
          -- would never see it.
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

-- `get_deck_states` is a function rather than the table itself, so the deck is
-- not queried on a cache hit. The agent-deck handle stays in `ui.lua`: the same
-- handle configures the plugin and feeds `session_tree`, so it is not the
-- rollup's to own.
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
