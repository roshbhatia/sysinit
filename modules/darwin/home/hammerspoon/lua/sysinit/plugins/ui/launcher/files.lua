local M = {}

local home = os.getenv("HOME") or ""

-- One display path per entry, in the same order as the lines of the fzf index.
-- A row is built from this only for the handful the panel draws, because the
-- home tree holds tens of thousands of paths and a table for each one would
-- cost more to allocate than the search that reads them.
local paths = {}
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
  return #paths
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

local function reload()
  local file = io.open(M.index, "r")
  if file == nil then
    return
  end
  local found = {}
  for line in file:lines() do
    local short = line:match("^%d+\t(.*)$")
    if short then
      found[#found + 1] = short
    end
  end
  file:close()
  paths = found
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

-- Built on demand, for a row the panel is about to draw.
---@param index number
---@return table|nil
function M.row(index)
  local short = paths[index]
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
