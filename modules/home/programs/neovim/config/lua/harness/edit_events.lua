-- Reads the edit-event log a harness hook writes, so a buffer reloads when an
-- agent writes the file instead of on the next `file_refresh` tick.
--
-- Nothing here names a harness. The log carries a label, and this module does no
-- more with it than show it. That is what lets the writing end stay ignorant of
-- the editor: a harness with no hook surface produces no events and this module
-- simply never fires, which is the behaviour that existed before it.
local M = {}

---@type userdata|nil
local watcher = nil

--- Byte offset already consumed. Starting at the log's current size rather than
--- at 0 is what keeps a late-starting Neovim from replaying a whole session as a
--- burst of reloads.
local offset = 0

---@type string|nil
local log_path = nil

--- Absolute paths an agent has written since this Neovim started, newest last.
---@type string[]
local touched = {}

---@type table<string, boolean>
local touched_seen = {}

--- Resolve the log by asking the writer for it. Deriving the path here would mean
--- a second implementation of the workspace and digest rule, and the two would
--- agree until they did not: the symptom would be a watcher tailing a file
--- nothing writes, which looks exactly like an idle agent.
---@return string|nil
local function resolve_log()
  if vim.fn.executable("agent-edit-event") ~= 1 then
    return nil
  end
  local out = vim.fn.system({ "agent-edit-event", "--print-log" })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  local path = vim.trim(out)
  if path == "" then
    return nil
  end
  return path
end

---@param path string
---@return integer
local function size_of(path)
  local stat = vim.uv.fs_stat(path)
  return (stat and stat.size) or 0
end

--- The buffer holding path, if any is loaded.
---@param path string
---@return integer|nil
local function loaded_buffer(path)
  local bufnr = vim.fn.bufnr(path)
  if bufnr == -1 or not vim.api.nvim_buf_is_loaded(bufnr) then
    return nil
  end
  return bufnr
end

---@param path string
local function remember(path)
  if touched_seen[path] then
    return
  end
  touched_seen[path] = true
  table.insert(touched, path)
end

--- React to one event. A modified buffer is never reloaded: the owner's unsaved
--- work is the one thing in this flow that cannot be reconstructed, so the
--- conflict is surfaced and the decision left to them.
---@param entry table
local function apply(entry)
  local path = entry.file
  if type(path) ~= "string" or path == "" then
    return
  end
  remember(path)

  local bufnr = loaded_buffer(path)
  if not bufnr then
    return
  end

  if vim.bo[bufnr].modified then
    vim.notify(
      string.format(
        "%s wrote %s, which you have unsaved changes in. Your buffer was left alone; :e! to take theirs.",
        entry.harness or "an agent",
        vim.fn.fnamemodify(path, ":t")
      ),
      vim.log.levels.WARN
    )
    return
  end

  vim.api.nvim_buf_call(bufnr, function()
    pcall(vim.cmd, "silent! checktime")
  end)
end

--- Read whatever arrived since the last read.
---
--- A file shorter than the offset means the writer truncated it past its size
--- bound, which replaces the file wholesale. Resetting to 0 re-reads what
--- survived; a handful of repeated reloads costs nothing, where holding a stale
--- offset would silently consume nothing ever again.
local function drain()
  if not log_path then
    return
  end

  local size = size_of(log_path)
  if size == offset then
    return
  end
  if size < offset then
    offset = 0
  end

  local handle = vim.uv.fs_open(log_path, "r", 438)
  if not handle then
    return
  end
  local body = vim.uv.fs_read(handle, size - offset, offset)
  vim.uv.fs_close(handle)
  if type(body) ~= "string" or body == "" then
    return
  end

  -- A partial trailing line means the writer is mid-append. Leave it in place by
  -- advancing only past what ended in a newline, so the rest arrives whole on the
  -- next event.
  local consumed = 0
  for line in body:gmatch("([^\n]*)\n") do
    consumed = consumed + #line + 1
    if line ~= "" then
      local ok, entry = pcall(vim.json.decode, line)
      if ok and type(entry) == "table" then
        apply(entry)
      end
    end
  end
  offset = offset + consumed
end

--- Watch the directory, not the file. Truncation replaces the log through a
--- rename, so a handle on the file would be left holding an unlinked inode and no
--- further event would ever arrive.
function M.start()
  if watcher then
    return
  end
  if not vim.uv then
    return
  end

  log_path = resolve_log()
  if not log_path then
    return
  end
  offset = size_of(log_path)

  watcher = vim.uv.new_fs_event()
  if not watcher then
    return
  end

  local dir = vim.fn.fnamemodify(log_path, ":h")
  vim.fn.mkdir(dir, "p")

  local ok = pcall(function()
    watcher:start(
      dir,
      {},
      vim.schedule_wrap(function(err)
        if err then
          return
        end
        drain()
      end)
    )
  end)
  if not ok then
    pcall(watcher.close, watcher)
    watcher = nil
  end
end

function M.stop()
  if not watcher then
    return
  end
  pcall(watcher.stop, watcher)
  pcall(watcher.close, watcher)
  watcher = nil
end

function M.is_active()
  return watcher ~= nil
end

--- The files an agent has written since this Neovim started, oldest first.
---
--- Incomplete rather than wrong: an event evicted by the writer's size bound, or
--- written before this Neovim started, is absent. Those files are still in the
--- working diff, which is why a caller must keep the full diff reachable.
---@return string[]
function M.touched_files()
  local present = {}
  for _, path in ipairs(touched) do
    if vim.uv.fs_stat(path) then
      table.insert(present, path)
    end
  end
  return present
end

function M.forget_touched()
  touched = {}
  touched_seen = {}
end

--- For `:checkhealth` and for answering "is this thing even on".
---@return table
function M.status()
  return {
    active = M.is_active(),
    log = log_path,
    offset = offset,
    touched = #touched,
  }
end

return M
