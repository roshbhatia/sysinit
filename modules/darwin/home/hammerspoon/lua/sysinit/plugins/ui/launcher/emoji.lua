local M = {}

local store = os.getenv("HOME") .. "/.local/state/sysinit/launcher_emoji.json"

local rows = nil
local picked = nil

---@return table<string, number>
local function load()
  if picked ~= nil then
    return picked
  end
  picked = {}
  local file = io.open(store, "r")
  if file then
    local content = file:read("*all")
    file:close()
    local ok, decoded = pcall(hs.json.decode, content or "")
    if ok and type(decoded) == "table" then
      picked = decoded
    end
  end
  return picked
end

local function save()
  hs.fs.mkdir(os.getenv("HOME") .. "/.local/state/sysinit")
  local file = io.open(store, "w")
  if file then
    file:write(hs.json.encode(load()))
    file:close()
  end
end

-- Read once and held, because the file is a build output that cannot change
-- while Hammerspoon is running.
---@param path string|nil
---@return table[]
function M.rows(path)
  if rows ~= nil then
    return rows
  end
  rows = {}
  if path == nil then
    return rows
  end
  local file = io.open(path, "r")
  if file == nil then
    return rows
  end
  local content = file:read("*all")
  file:close()
  local ok, decoded = pcall(hs.json.decode, content or "")
  if ok and type(decoded) == "table" then
    rows = decoded
  end
  return rows
end

-- Kept apart from the launcher's own recency file. An emoji is picked far more
-- often than an app is opened, and sharing one file would let the emoji push
-- every app off the top of the list the empty query shows.
---@return table<string, number>
function M.recent()
  return load()
end

---@param code string
function M.touch(code)
  if code == nil or code == "" then
    return
  end
  local all = load()
  all[code] = os.time()
  save()
end

---@param cp string
function M.copy(cp)
  hs.pasteboard.setContents(cp)
end

return M
