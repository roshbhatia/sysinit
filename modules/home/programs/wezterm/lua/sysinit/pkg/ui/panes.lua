local wezterm = require("wezterm")
local utils = require("sysinit.pkg.utils")

-- Pane primitives. Everything here reads ONE pane and answers one question
-- about it, so both mux walks can share it without sharing a reducer.
--
-- `compute_agent_session_states` and `session_tree` both read all four of
-- these. That is why they are here and not inside the rollup: the tree needs
-- the primitives and never touches the rollup's cache.
local M = {}

-- Precedence when two panes collapse to one entry. Higher wins.
M.state_rank = {
  waiting = 4,
  done    = 3,
  working = 2,
  idle    = 1,
}

function M.pane_repo(p)
  local ok, repo, cwd = pcall(function()
    local url = p:get_current_working_dir()
    if not url then return "", "" end
    local path
    if type(url) == "string" then
      path = url:gsub("^file://[^/]*", "")
    else
      path = url.file_path
    end
    if not path or path == "" then return "", "" end
    path = path:gsub("/+$", "")
    return path:match("([^/]+)$") or "", path
  end)
  if not ok then return "", "" end
  return repo or "", cwd or ""
end

-- Reads the pane record file for `session`, `branch`, and `dirty`, which the
-- OSC user variable does not carry. Schema:
-- pkgs/sysinit-agent/internal/agentstate/SCHEMA.md.
--
-- The liveness rule is pane existence, and the caller already satisfies it:
-- every id reaching here comes from `tab:panes_with_info()`, so a record whose
-- pane is gone is a record nothing asks for. The record's `mux` marker is not
-- checked, because the GUI process carries no `WEZTERM_UNIX_SOCKET` and so
-- cannot tell which mux it is. `agent-state` deletes dead muxes' records
-- instead.
function M.read_pane_record(pane_id)
  local path = utils.state_path("agentPanes", "agents/panes") .. "/" .. tostring(pane_id) .. ".json"
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(wezterm.json_parse, content)
  if not ok or type(data) ~= "table" then return nil end
  return {
    session = type(data.session) == "string" and data.session or "",
    branch = type(data.branch) == "string" and data.branch ~= "" and data.branch or nil,
    dirty  = data.dirty == true,
  }
end

function M.agent_state(p, deck_states)
  local status, reason, since, agent
  local uv = p:get_user_vars()
  local raw = uv and uv.agent_state
  if raw and raw ~= "" then
    local s, r, ts, a = raw:match("^([^|]*)|([^|]*)|([^|]*)|(.*)$")
    if s and M.state_rank[s] then
      status, reason, since, agent = s, r, tonumber(ts), a
    end
  end
  if not status then
    local deck = deck_states[p:pane_id()]
    if deck and M.state_rank[deck.status] then
      status = deck.status -- working | waiting | idle; no reason/age
      agent = deck.agent
    end
  end
  return status, reason, since, agent
end

return M
