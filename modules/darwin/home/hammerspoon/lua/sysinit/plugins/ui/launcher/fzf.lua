local M = {}

local dir = os.getenv("HOME") .. "/.local/state/sysinit/launcher"

M.bin = nil

---@param text string
---@return string
local function quote(text)
  return "'" .. tostring(text):gsub("'", "'\\''") .. "'"
end

-- The index directory has to exist before anything writes into it, including
-- the shell pipelines that write their own index.
function M.ensure()
  hs.fs.mkdir(os.getenv("HOME") .. "/.local/state/sysinit")
  hs.fs.mkdir(dir)
end

---@param name string
---@return string
function M.index_path(name)
  return dir .. "/" .. name .. ".tsv"
end

-- Each list keeps its rows in a file rather than handing them to fzf on stdin,
-- because the file index runs to megabytes and a keystroke must not pay for
-- shipping it through the task pipe every time.
---@param name string
---@param haystacks string[]
---@return string|nil path
function M.write_index(name, haystacks)
  M.ensure()
  local path = M.index_path(name)
  local file = io.open(path .. ".tmp", "w")
  if file == nil then
    return nil
  end
  local parts = {}
  for index, text in ipairs(haystacks) do
    parts[#parts + 1] = index .. "\t" .. tostring(text):gsub("[\t\n]", " ")
  end
  file:write(table.concat(parts, "\n"))
  if #parts > 0 then
    file:write("\n")
  end
  file:close()
  os.rename(path .. ".tmp", path)
  return path
end

---@param opts table { name, query, limit }
---@param cb fun(indices: number[]|nil)
function M.filter(opts, cb)
  if M.bin == nil then
    return cb(nil)
  end
  local command = string.format(
    "exec %s --filter=%s --delimiter='\\t' --nth=2.. --no-multi < %s | head -n %d",
    quote(M.bin),
    quote(opts.query),
    quote(M.index_path(opts.name)),
    opts.limit or 300
  )
  -- fzf exits 1 when nothing matched, which is an empty result and not a failure.
  local task = hs.task.new("/bin/sh", function(_, out)
    local indices = {}
    for line in tostring(out or ""):gmatch("[^\n]+") do
      local at = tonumber(line:match("^(%d+)\t"))
      if at then
        indices[#indices + 1] = at
      end
    end
    cb(indices)
  end, { "-c", command })
  if task == nil then
    return cb(nil)
  end
  task:start()
end

return M
