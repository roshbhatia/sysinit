-- The session tree's reading of a roster.catalog/v1 row's `spawn`. roster and
-- its sources decide the plan and the hop; this module only turns them into
-- the table SwitchToWorkspace takes, so it runs under plain lua with no GUI.
local wezterm = require("wezterm")

local M = {}

-- One deferred spawn may answer with a plan; it may not defer again.
M.MAX_RESOLVE_DEPTH = 1

-- An empty command is the display's default program, so it yields no args.
local function command_args(plan)
  local command = type(plan) == "table" and plan.command or nil
  if type(command) ~= "table" or #command == 0 then
    return nil
  end
  return command
end

local function non_empty(text)
  if type(text) == "string" and text ~= "" then
    return text
  end
  return nil
end

-- The spawn a SwitchToWorkspace takes for a row, or nil and why not. A native
-- hop runs the command at the named WezTerm domain, in the row's own directory.
-- A local hop runs the command in a local pane, in the plan's directory, which
-- is empty when the row's directory is not on this machine. A row roster
-- rejected carries `reason` and never spawns.
---@param row table|nil a catalog row
---@param resolve nil|fun(id: string): table|nil, string|nil answers a deferred spawn with the row `roster open --json` prints
---@param depth integer|nil
---@return table|nil spawn { domain?, cwd?, args? }
---@return string|nil err
function M.spawn_for(row, resolve, depth)
  depth = depth or 0
  if type(row) ~= "table" then
    return nil, "no catalog row"
  end
  local reason = non_empty(row.reason)
  if reason then
    return nil, reason
  end
  local spawn = row.spawn
  if type(spawn) ~= "table" then
    return nil, "row has no spawn"
  end
  if spawn.resolve == true then
    if depth >= M.MAX_RESOLVE_DEPTH then
      return nil, "source.open answered with another deferred spawn"
    end
    if type(resolve) ~= "function" then
      return nil, "deferred spawn with no resolver"
    end
    local resolved, err = resolve(row.id)
    if type(resolved) ~= "table" then
      return nil, err or ("roster open " .. tostring(row.id) .. " answered nothing")
    end
    return M.spawn_for(resolved, resolve, depth + 1)
  end
  local hop = type(spawn.hop) == "table" and spawn.hop or {}
  local args = command_args(spawn.plan)
  if hop.kind == "native" then
    local ref = non_empty(hop.ref)
    if not ref then
      return nil, "native hop names no domain"
    end
    return { domain = { DomainName = ref }, cwd = non_empty(row.cwd), args = args }
  elseif hop.kind == "local" then
    local cwd = type(spawn.plan) == "table" and non_empty(spawn.plan.cwd) or nil
    return { cwd = cwd, args = args }
  end
  return nil, "unknown hop kind " .. tostring(hop.kind)
end

-- The resolver the GUI hands spawn_for: `roster open --json <id>`, through
-- the wrapper config.json names, run synchronously. This is the one
-- run_child_process the session tree makes on the GUI thread. A deferred
-- spawn cannot be answered from the catalog on disk, roster has to ask the
-- owning source, and the keypress that asked for it is already waiting on the
-- answer; roster bounds the call with the source's own timeout.
---@param bin string|nil
---@return fun(id: string): table|nil, string|nil
function M.resolver(bin)
  return function(id)
    if not bin or bin == "" then
      return nil, "no roster open command configured"
    end
    local ran, success, stdout, stderr = pcall(wezterm.run_child_process, { bin, id })
    if not ran then
      return nil, tostring(success)
    end
    if not success then
      local detail = type(stderr) == "string" and stderr:gsub("%s+$", "") or ""
      return nil, "roster open " .. tostring(id) .. " failed" .. (detail ~= "" and (": " .. detail) or "")
    end
    local parsed, row = pcall(wezterm.json_parse, stdout or "")
    if not parsed or type(row) ~= "table" then
      return nil, "roster open " .. tostring(id) .. " printed no row"
    end
    return row
  end
end

return M
