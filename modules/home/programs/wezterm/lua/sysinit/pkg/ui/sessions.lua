local wezterm = require("wezterm")
local utils = require("sysinit.pkg.utils")
local ui_format = require("sysinit.pkg.ui.format")

local M = {}

M.DEFAULT_WORKSPACE = "default"
M.DEFAULT_SLOT = 1
M.MAX_SLOT = 9
M.HOST_SEP = ":"
M.REMOTE_REFRESH_SECS = 30

local home = os.getenv("HOME") or ""

M.seshy_dir = utils.state_path("seshySessions", "seshy/sessions")
M.remote_dir = utils.state_path("weztermRemoteSessions", "wezterm/remote_sessions")

M.remote_lister = ""
do
  local ok, cfg = pcall(utils.load_json_file, utils.get_config_path("config.json"))
  if ok and type(cfg) == "table" and type(cfg.scripts) == "table" then
    M.remote_lister = cfg.scripts.seshy_remote_list or ""
  end
end

M.sy_bin = home .. "/.local/bin/sy"
do
  local env = utils.load_json_file(utils.get_config_path("env.json"))
  for dir in (env and env.PATH or ""):gmatch("[^:]+") do
    local candidate = dir .. "/sy"
    local fh = io.open(candidate, "r")
    if fh then
      fh:close()
      M.sy_bin = candidate
      break
    end
  end
end

function M.list_names(sy_bin)
  if not sy_bin or sy_bin == "" then
    return {}, false
  end
  local names = {}
  local ok, out = pcall(function()
    local success, stdout = wezterm.run_child_process({ sy_bin, "list", "--names" })
    if not success then
      error("sy list failed")
    end
    return stdout
  end)
  if not ok or not out then
    return {}, false
  end
  for _, line in ipairs(wezterm.split_by_newlines(out)) do
    local name = line:match("^%s*(.-)%s*$")
    if name ~= "" then
      names[#names + 1] = name
    end
  end
  return names, true
end

local seshy_cache = { at = -1, names = {} }

function M.names_cached()
  local now = os.time()
  if now - seshy_cache.at >= 5 then
    local names, ok = M.list_names(M.sy_bin)
    if ok then
      seshy_cache = { at = now, names = names }
    else
      seshy_cache.at = now
    end
  end
  return seshy_cache.names
end

-- Only an attached domain is safe to probe. A detached one would stall the
-- refresher on an ssh connect timeout for a host that is not even in use.
function M.remote_hosts()
  local hosts, at = {}, {}
  pcall(function()
    for _, domain in ipairs(wezterm.mux.all_domains()) do
      if domain:state() == "Attached" then
        local name = domain:name()
        local host, is_local = ui_format.domain_host(name)
        if not is_local then
          local index = at[host]
          if not index then
            hosts[#hosts + 1] = { host = host, domain = name }
            at[host] = #hosts
          elseif not name:match("^SSHMUX:") then
            -- Prefer the configured `ssh:<host>`; the inner SSHMUX name is not
            -- a valid spawn target.
            hosts[index].domain = name
          end
        end
      end
    end
  end)
  table.sort(hosts, function(a, b)
    return a.host < b.host
  end)
  return hosts
end

local remote_cache = { at = -1, hosts = {} }

function M.remote_cached()
  local now = os.time()
  if now - remote_cache.at < 5 then
    return remote_cache.hosts
  end
  local out = {}
  for _, entry in ipairs(M.remote_hosts()) do
    local ok, data = pcall(utils.load_json_file, M.remote_dir .. "/" .. entry.host .. ".json")
    local cached = (ok and type(data) == "table") and data or nil
    out[#out + 1] = {
      host = entry.host,
      domain = entry.domain,
      ok = cached ~= nil and cached.ok == true,
      reason = cached and cached.reason or (cached == nil and "not probed yet" or nil),
      shell = cached and cached.shell or nil,
      sessions = (cached and type(cached.sessions) == "table") and cached.sessions or {},
    }
  end
  remote_cache = { at = now, hosts = out }
  return out
end

local remote_refresh_at = -1

function M.refresh_remote()
  local now = os.time()
  if now - remote_refresh_at < M.REMOTE_REFRESH_SECS or M.remote_lister == "" then
    return
  end
  local hosts = M.remote_hosts()
  remote_refresh_at = now
  if #hosts == 0 then
    return
  end
  local args = { M.remote_lister, M.remote_dir }
  for _, entry in ipairs(hosts) do
    args[#args + 1] = entry.host
  end
  pcall(function()
    wezterm.background_child_process(args)
  end)
end

function M.qualify(host, name)
  return host .. M.HOST_SEP .. name
end

-- Splits only on a host that is attached right now, so a local session whose
-- own name contains a colon is never read as a remote one.
---@return string|nil host
---@return string name
---@return string|nil domain
function M.split(workspace, hosts)
  for _, entry in ipairs(hosts or M.remote_cached()) do
    local prefix = entry.host .. M.HOST_SEP
    if workspace:sub(1, #prefix) == prefix then
      return entry.host, workspace:sub(#prefix + 1), entry.domain
    end
  end
  return nil, workspace, nil
end

-- Everything a spawn needs for a host-qualified workspace, or nil when the
-- workspace is local.
function M.remote_spawn(workspace)
  local host, name = M.split(workspace)
  if not host then
    return nil
  end
  for _, entry in ipairs(M.remote_cached()) do
    if entry.host == host then
      for _, session in ipairs(entry.sessions) do
        if session.name == name then
          -- `cwd`, not `path`: this table is read by switch_to_workspace, whose
          -- spawn takes a cwd. Named `path` it type-checked and silently landed
          -- every remote session in the login home instead of the session dir.
          return { domain = entry.domain, cwd = session.path, shell = entry.shell, session = name }
        end
      end
      return { domain = entry.domain, shell = entry.shell, session = name }
    end
  end
  return nil
end

function M.active_names()
  local seen, names = {}, {}
  pcall(function()
    for _, win in ipairs(wezterm.mux.all_windows()) do
      local n = win:get_workspace()
      if n and n ~= "" and not seen[n] then
        seen[n] = true
        names[#names + 1] = n
      end
    end
  end)
  return names
end

local function compute_slots()
  local prev = wezterm.GLOBAL.workspace_slots
  if type(prev) ~= "table" then
    prev = {}
  end

  local names = M.active_names()
  if #names == 0 then
    return prev
  end

  local present = {}
  for _, n in ipairs(names) do
    present[n] = true
  end

  local slots, taken = {}, {}
  taken[M.DEFAULT_SLOT] = true
  for name, slot in pairs(prev) do
    if present[name] and name ~= M.DEFAULT_WORKSPACE and type(slot) == "number" and not taken[slot] then
      slots[name] = slot
      taken[slot] = true
    end
  end

  local fresh = {}
  for _, n in ipairs(names) do
    if n ~= M.DEFAULT_WORKSPACE and not slots[n] then
      fresh[#fresh + 1] = n
    end
  end
  table.sort(fresh)
  local probe = 1
  for _, name in ipairs(fresh) do
    while probe <= M.MAX_SLOT and taken[probe] do
      probe = probe + 1
    end
    if probe > M.MAX_SLOT then
      break
    end
    slots[name] = probe
    taken[probe] = true
  end

  slots[M.DEFAULT_WORKSPACE] = M.DEFAULT_SLOT

  local changed = false
  for name, slot in pairs(slots) do
    if prev[name] ~= slot then
      changed = true
      break
    end
  end
  if not changed then
    for name in pairs(prev) do
      if slots[name] == nil then
        changed = true
        break
      end
    end
  end
  if changed then
    wezterm.GLOBAL.workspace_slots = slots
  end
  return slots
end

local slots_cache = { at = -1, slots = {} }

function M.slots()
  local now = os.time()
  if now ~= slots_cache.at then
    slots_cache = { at = now, slots = compute_slots() }
  end
  return slots_cache.slots
end

local touch_throttle = {}

function M.touch(name)
  if not name or name == "" then
    return
  end
  local now = os.time()
  if touch_throttle[name] and now - touch_throttle[name] < 5 then
    return
  end
  touch_throttle[name] = now
  local t = wezterm.GLOBAL.workspace_last_active or {}
  t[name] = now
  wezterm.GLOBAL.workspace_last_active = t
end

function M.last_active(name)
  local t = wezterm.GLOBAL.workspace_last_active
  return type(t) == "table" and t[name] or nil
end

return M
