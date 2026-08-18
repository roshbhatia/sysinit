local wezterm = require("wezterm")
local utils = require("sysinit.pkg.utils")

local M = {}

M.state_rank = {
  waiting = 4,
  done = 3,
  working = 2,
  idle = 1,
}

function M.pane_domain(p)
  local ok, name = pcall(function()
    return p:get_domain_name()
  end)
  if not ok or type(name) ~= "string" then
    return ""
  end
  return name
end

function M.pane_repo(p)
  local ok, repo, cwd = pcall(function()
    local url = p:get_current_working_dir()
    if not url then
      return "", ""
    end
    local path
    if type(url) == "string" then
      path = url:gsub("^file://[^/]*", "")
    else
      path = url.file_path
    end
    if not path or path == "" then
      return "", ""
    end
    path = path:gsub("/+$", "")
    return path:match("([^/]+)$") or "", path
  end)
  if not ok then
    return "", ""
  end
  return repo or "", cwd or ""
end

function M.read_pane_record(pane_id)
  local path = utils.state_path("agentPanes", "agents/panes") .. "/" .. tostring(pane_id) .. ".json"
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(wezterm.json_parse, content)
  if not ok or type(data) ~= "table" then
    return nil
  end
  local repo_count = 0
  if type(data.repos) == "table" then
    repo_count = #data.repos
  end

  return {
    session = type(data.session) == "string" and data.session or "",
    repo = type(data.repo) == "string" and data.repo or "",
    branch = type(data.branch) == "string" and data.branch ~= "" and data.branch or nil,
    dirty = data.dirty == true,
    repo_count = repo_count,
    worktree = type(data.worktree) == "string" and data.worktree ~= "" and data.worktree or nil,
    status = type(data.status) == "string" and M.state_rank[data.status] and data.status or nil,
    reason = type(data.reason) == "string" and data.reason or "",
    since = tonumber(data.since),
    agent = type(data.agent) == "string" and data.agent or "",
  }
end

-- The OSC user var and the pane record carry the same four fields over two
-- channels. Only the record survives a VT that does not forward OSC (zmx, and
-- any ssh mux), so the fresher of the two wins rather than the user var always.
---@return string|nil status
---@return string reason
---@return number|nil since
---@return string|nil agent
---@return string source one of "record", "uservar", "deck", or ""
---@param record table|false|nil pass the already-read record, false for none, nil to read here
function M.agent_state(p, deck_states, record)
  local status, reason, since, agent, source

  local uv = p:get_user_vars()
  local raw = uv and uv.agent_state
  if raw and raw ~= "" then
    local s, r, ts, a = raw:match("^([^|]*)|([^|]*)|([^|]*)|(.*)$")
    if s and M.state_rank[s] then
      status, reason, since, agent, source = s, r, tonumber(ts), a, "uservar"
    end
  end

  if record == nil then
    record = M.read_pane_record(p:pane_id())
  end
  if record and record.status and (since == nil or (record.since or 0) > since) then
    status, reason, since, agent, source = record.status, record.reason, record.since, record.agent, "record"
  end

  if not status then
    local deck = deck_states[p:pane_id()]
    if deck and M.state_rank[deck.status] then
      status, agent, source = deck.status, deck.agent, "deck"
    end
  end

  return status, reason, since, agent, source or ""
end

return M
