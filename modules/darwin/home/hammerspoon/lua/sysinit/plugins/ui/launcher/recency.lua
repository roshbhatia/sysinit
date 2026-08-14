local M = {}

local store = os.getenv("HOME") .. "/.local/state/sysinit/launcher_recency.json"

local opened = nil

---@param row table
---@return string
local function key(row)
  return (row.kind or "?") .. ":" .. (row.text or "")
end

---@return table<string, number>
local function load()
  if opened ~= nil then
    return opened
  end
  opened = {}
  local file = io.open(store, "r")
  if file then
    local content = file:read("*all")
    file:close()
    local ok, decoded = pcall(hs.json.decode, content or "")
    if ok and type(decoded) == "table" then
      opened = decoded
    end
  end
  return opened
end

local function save()
  hs.fs.mkdir(os.getenv("HOME") .. "/.local/state/sysinit")
  local file = io.open(store, "w")
  if file then
    file:write(hs.json.encode(load()))
    file:close()
  end
end

---@param row table
function M.touch(row)
  local all = load()
  all[key(row)] = os.time()
  save()
end

---@param rows table[]
---@return table[]
function M.sort(rows)
  local all = load()
  local ranked = {}
  for index, row in ipairs(rows) do
    ranked[index] = {
      row = row,
      at = row.at or all[key(row)] or 0,
      index = index,
    }
  end
  table.sort(ranked, function(a, b)
    if a.at ~= b.at then
      return a.at > b.at
    end
    if a.at == 0 and b.at == 0 then
      local left, right = a.row.text or "", b.row.text or ""
      if left ~= right then
        return left < right
      end
    end
    return a.index < b.index
  end)
  local sorted = {}
  for index, entry in ipairs(ranked) do
    sorted[index] = entry.row
  end
  return sorted
end

return M
