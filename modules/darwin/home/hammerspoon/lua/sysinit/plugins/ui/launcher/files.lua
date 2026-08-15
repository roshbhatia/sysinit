local M = {}

local home = os.getenv("HOME") or ""

-- Only what the panel shows before a query is typed, and how many there are in
-- all. The index file is the list; matching reads it out of process and hands
-- back the lines it matched, so nothing here has to hold the home tree. Reading
-- it into Lua cost a fifth of a second on the main thread every rebuild, for a
-- table that every search then ignored.
local HEAD = 300

local head = {}
local total = 0
local building = false

M.fd = nil
M.timeout = nil
M.roots = {}
M.excludes = {}
M.cap = 150000
-- Seconds the walk may run before it is killed. A TCC-protected directory that
-- Hammerspoon holds no grant for blocks readdir with no prompt anybody can
-- answer, so an unbounded walk hangs and publishes nothing at all.
M.deadline = 15
-- Where the walk writes its index. fzf reads this file, and so does this module.
M.index = nil

---@param text string
---@return string
local function quote(text)
  return "'" .. tostring(text):gsub("'", "'\\''") .. "'"
end

---@return number
function M.count()
  return total
end

---@return string
local function command()
  -- The kill lands on fd, so head and awk read a clean end of input and exit 0.
  -- That is what lets the rename below publish the part of the walk that did
  -- finish rather than throwing it away.
  local args = {
    quote(M.timeout),
    tostring(M.deadline),
    quote(M.fd),
    "--type",
    "f",
    "--type",
    "d",
    "--hidden",
  }
  for _, name in ipairs(M.excludes) do
    args[#args + 1] = "--exclude"
    args[#args + 1] = quote(name)
  end
  args[#args + 1] = "."
  for _, root in ipairs(M.roots) do
    args[#args + 1] = quote(root)
  end

  -- The index is written in the shape fzf reads: the line number, a tab, then
  -- the path with the home prefix shortened. Doing it here rather than in Lua
  -- keeps a walk of the whole home tree off the Hammerspoon main thread.
  local shape = [[{ p = $0; sub(/\/$/, "", p); s = p; ]]
    .. [[if (substr(p, 1, length(h) + 1) == h "/") { s = "~" substr(p, length(h) + 1) } ]]
    .. [[gsub(/\t/, " ", s); print NR "\t" s }]]

  return table.concat(args, " ")
    .. " 2>/dev/null | head -n "
    .. tostring(M.cap)
    .. " | awk -v h="
    .. quote(home)
    .. " "
    .. quote(shape)
    .. " > "
    .. quote(M.index .. ".tmp")
    .. " && mv -f "
    .. quote(M.index .. ".tmp")
    .. " "
    .. quote(M.index)
end

-- The walk numbers its own lines, so the number on the last one is how many
-- there are. Read from the end of the file rather than by counting, because
-- counting means reading all of it.
---@param file file*
---@return number
local function written(file)
  local size = file:seek("end")
  local back = math.min(size, 4096)
  file:seek("set", size - back)
  local chunk = file:read(back) or ""
  local last = chunk:match(".*\n(%d+)\t") or chunk:match("^(%d+)\t")
  return tonumber(last) or 0
end

local function reload()
  local file = io.open(M.index, "r")
  if file == nil then
    return
  end
  local found = {}
  for line in file:lines() do
    if #found >= HEAD then
      break
    end
    local short = line:match("^%d+\t(.*)$")
    if short then
      found[#found + 1] = short
    end
  end
  head = found
  total = written(file)
  file:close()
end

---@param cb fun()|nil
function M.build(cb)
  if M.fd == nil or M.timeout == nil or M.index == nil or building then
    if cb then
      cb()
    end
    return
  end
  building = true

  local task = hs.task.new("/bin/sh", function()
    reload()
    building = false
    if cb then
      cb()
    end
  end, { "-c", command() })

  if task == nil then
    building = false
    if cb then
      cb()
    end
    return
  end
  task:start()
end

---@param short string
---@return string
local function expand(short)
  if short == "~" then
    return home
  end
  if short:sub(1, 2) == "~/" then
    return home .. "/" .. short:sub(3)
  end
  return short
end

-- Built on demand, for a row the panel is about to draw. The text is the line
-- matching handed back; without one, only the head of the list can be resolved.
---@param index number
---@param text string|nil
---@return table|nil
function M.row(index, text)
  local short = text or head[index]
  if short == nil then
    return nil
  end
  return {
    text = short:match("([^/]+)$") or short,
    detail = short,
    label = "File",
    glyph = "file",
    kind = "file-entry",
    path = expand(short),
  }
end

-- What the panel shows before anything is typed.
---@param limit number
---@return table[]
function M.head(limit)
  local rows = {}
  for index = 1, math.min(#head, limit) do
    rows[index] = M.row(index, head[index])
  end
  return rows
end

---@param path string
function M.open(path)
  hs.task.new("/usr/bin/open", nil, { path }):start()
end

---@param path string
function M.reveal(path)
  hs.task.new("/usr/bin/open", nil, { "-R", path }):start()
end

---@param path string
function M.copy(path)
  hs.pasteboard.setContents(path)
end

return M
