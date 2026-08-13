-- What was opened, and when. The launcher sorts by it, because the row a reader wants is
-- almost always one they have opened before, and alphabetical order buries it.
local M = {}

-- Written to disk, unlike the clipboard, because a row's name and the time it was opened
-- is not a secret and a launcher that forgets its order on every reload is not one.
local store = os.getenv("HOME") .. "/.local/state/sysinit/launcher_recency.json"

local opened = nil

--- What identifies a row across opens. The kind as well as the text, because a session and
--- a pane can carry the same name and are not the same row.
---@param row table
---@return string
local function key(row)
  return (row.kind or "?") .. ":" .. (row.text or "")
end

--- Read the store once.
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

--- Write the store, creating its directory the first time.
local function save()
  hs.fs.mkdir(os.getenv("HOME") .. "/.local/state/sysinit")
  local file = io.open(store, "w")
  if file then
    file:write(hs.json.encode(load()))
    file:close()
  end
end

--- Record that a row was opened now.
---@param row table
function M.touch(row)
  local all = load()
  all[key(row)] = os.time()
  save()
end

--- Sort rows: the ones opened before in the order they were last opened, then the rest.
--- The clipboard keeps its own order, since a clipboard row's recency is when it was
--- copied and not when it was chosen.
---@param rows table[]
---@return table[]
function M.sort(rows)
  local all = load()
  local ranked = {}
  for index, row in ipairs(rows) do
    ranked[index] = {
      row = row,
      -- A clipboard row ranks by when it was copied, which is already a recency.
      at = row.at or all[key(row)] or 0,
      -- The original position, so the sort is stable for rows that tie at zero and the
      -- list does not reshuffle between two draws of the same set.
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
