-- The session tree's reading of a tether.plan/v1 document. tether decides the
-- hop; this module only turns its JSON into a row suffix or a spawn, so it runs
-- under plain lua against a fixture with no GUI.
local M = {}

M.PLAN_VERSION = "tether.plan/v1"

-- The two costs a wezterm user feels. OSC is every user-var and cwd signal this
-- config drives, and native panes are the difference between a split and a
-- whole far-side multiplexer. Roaming and local echo are quiet trade-offs, not
-- losses to flag.
M.flagged = {
  { "osc", "no osc" },
  { "native-panes", "no panes" },
}

-- What a row shows about a host: the tier that won, what the hop costs, and
-- whether the inventory behind it is stale. nil when there is no plan yet.
---@param plan table|nil
---@return table|nil summary { tier, stale, loses = { [cap] = true }, error }
function M.summary(plan)
  if type(plan) ~= "table" or plan.version ~= M.PLAN_VERSION then
    return nil
  end
  local loses = {}
  for _, cap in ipairs(plan.loses or {}) do
    loses[cap] = true
  end
  local probe = type(plan.probe) == "table" and plan.probe or {}
  local err
  if plan.status ~= "ok" then
    err = plan.error or "plan failed"
  end
  return {
    tier = type(plan.chosen) == "table" and plan.chosen.tier or nil,
    stale = probe.stale == true,
    loses = loses,
    error = err,
  }
end

-- Empty for a plan that keeps both flagged capabilities, so the native-mux
-- tier draws the row it always drew.
---@param summary table|nil
---@return string
function M.loses_suffix(summary)
  if not summary then
    return ""
  end
  if summary.error then
    return summary.error
  end
  local parts = {}
  for _, pair in ipairs(M.flagged) do
    if summary.loses[pair[1]] then
      parts[#parts + 1] = pair[2]
    end
  end
  return table.concat(parts, " ")
end

-- The argv for `tether plan`. `native_ref` is the caller's WezTerm ssh domain,
-- echoed back as hop.ref and never parsed by tether. `inner` is wrapped by the
-- hop, never composed.
function M.plan_args(bin, host, session, native_ref, inner)
  local args = { bin, "plan", "--host", host, "--session", session }
  if native_ref and native_ref ~= "" then
    args[#args + 1] = "--native"
    args[#args + 1] = native_ref
  end
  args[#args + 1] = "--"
  for _, arg in ipairs(inner) do
    args[#args + 1] = arg
  end
  return args
end

-- The spawn a SwitchToWorkspace takes for a plan, or nil and why not. A native
-- hop runs the command at the ssh domain, in the session's own directory. A
-- local hop runs the hop tool (mosh, ssh) in a local pane, where a remote cwd
-- would fail the spawn.
---@param plan table|nil
---@param cwd string|nil
---@return table|nil spawn
---@return string|nil err
function M.spawn_for(plan, cwd)
  if type(plan) ~= "table" or plan.version ~= M.PLAN_VERSION then
    return nil, "no tether.plan/v1 document"
  end
  if plan.status ~= "ok" then
    return nil, (plan.error or "plan failed") .. "; " .. table.concat(plan.reasons or {}, "; ")
  end
  local command = type(plan.plan) == "table" and plan.plan.command or nil
  if type(command) ~= "table" or #command == 0 then
    return nil, "plan has no command"
  end
  local hop = type(plan.hop) == "table" and plan.hop or {}
  if hop.kind == "native" then
    if type(hop.ref) ~= "string" or hop.ref == "" then
      return nil, "native hop names no domain"
    end
    return { domain = { DomainName = hop.ref }, args = command, cwd = cwd }
  elseif hop.kind == "local" then
    return { args = command }
  end
  return nil, "unknown hop kind " .. tostring(hop.kind)
end

return M
