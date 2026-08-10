local M = {}

local persist = require("harness.persist")
local STATE_FILE = persist.path("frecency")
local HALF_LIFE_S = 7 * 24 * 3600

---@type table<string, { count: integer, last_ts: integer }>
local state = {}
local loaded = false

local function load()
  if loaded then
    return
  end
  loaded = true
  state = persist.load(STATE_FILE) or {}
end

local function save()
  persist.save(STATE_FILE, state)
end

---@param name string
function M.record(name)
  if not name or name == "" then
    return
  end
  load()
  local entry = state[name] or { count = 0, last_ts = 0 }
  entry.count = entry.count + 1
  entry.last_ts = os.time()
  state[name] = entry
  save()
end

---@param name string
---@return number
function M.score(name)
  load()
  local entry = state[name]
  if not entry or (entry.count or 0) == 0 then
    return 0
  end
  local age = os.time() - (entry.last_ts or 0)
  if age < 0 then
    age = 0
  end
  return entry.count * math.exp(-age / HALF_LIFE_S)
end

---@param adapters table[]
function M.sort(adapters)
  load()
  local rank = {}
  for i, a in ipairs(adapters) do
    rank[a.name] = i
  end
  table.sort(adapters, function(a, b)
    local sa, sb = M.score(a.name), M.score(b.name)
    if sa ~= sb then
      return sa > sb
    end
    return (rank[a.name] or 0) < (rank[b.name] or 0)
  end)
end

return M
