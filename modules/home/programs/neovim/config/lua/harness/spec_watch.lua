
local M = {}

local DEBOUNCE_MS = 250

local state = { handle = nil, timer = nil, pending = nil, root = nil }

---@return string|nil
local function openspec_root()
  local found = vim.fs.find("openspec", { upward = true, type = "directory", path = vim.fn.getcwd() })[1]
  if not found then
    return nil
  end
  return found
end

---@param path string
---@return boolean
local function watchable(path)
  if not path:match("%.md$") then
    return false
  end
  if path:find("/changes/archive/", 1, true) then
    return false
  end
  return path:find("/openspec/", 1, true) ~= nil
end

local function flush()
  local path = state.pending
  state.pending = nil
  if not path or vim.fn.filereadable(path) == 0 then
    return
  end
  require("harness.preview").open(path, { focus = false })
end

---@param filename string|nil
local function on_event(filename)
  if not filename or not state.root then
    return
  end
  local path = filename
  if not path:match("^/") then
    path = vim.fs.joinpath(state.root, filename)
  end
  path = vim.fn.fnamemodify(path, ":p")
  if not watchable(path) then
    return
  end
  state.pending = path
  if state.timer then
    state.timer:stop()
    state.timer:start(DEBOUNCE_MS, 0, vim.schedule_wrap(flush))
  end
end

function M.is_active()
  return state.handle ~= nil
end

---@return boolean started
function M.start()
  if state.handle then
    return true
  end
  local root = openspec_root()
  if not root then
    return false
  end
  local handle = vim.uv.new_fs_event()
  if not handle then
    return false
  end
  local ok = pcall(function()
    handle:start(root, { recursive = true }, function(_err, filename, _events)
      vim.schedule(function()
        on_event(filename)
      end)
    end)
  end)
  if not ok then
    pcall(handle.close, handle)
    return false
  end
  state.handle = handle
  state.root = root
  state.timer = vim.uv.new_timer()
  return true
end

function M.stop()
  if state.timer then
    pcall(state.timer.stop, state.timer)
    pcall(state.timer.close, state.timer)
    state.timer = nil
  end
  if state.handle then
    pcall(state.handle.stop, state.handle)
    pcall(state.handle.close, state.handle)
    state.handle = nil
  end
  state.root, state.pending = nil, nil
end

function M.toggle()
  if M.is_active() then
    M.stop()
    vim.notify("Harness: spec watch off", vim.log.levels.INFO)
    return
  end
  if M.start() then
    vim.notify("Harness: spec watch on (" .. state.root .. ")", vim.log.levels.INFO)
  else
    vim.notify("Harness: no openspec/ directory above " .. vim.fn.getcwd(), vim.log.levels.WARN)
  end
end

function M.setup()
  vim.api.nvim_create_user_command("HarnessSpecWatch", function()
    M.toggle()
  end, { desc = "Harness: toggle openspec artifact auto-preview" })

  -- No M.start() here. The watcher is opt-in: run :HarnessSpecWatch to turn it
  -- on. It used to start unconditionally, which opened a preview the owner
  -- never asked for.
  --
  -- The guard below is the other half of that edit and is not optional.
  -- Re-rooting on DirChanged is still right, because the watcher is anchored to
  -- an openspec/ directory and a cd can move it. But the callback was stop-then-
  -- start with no condition, so it would restart the watcher after the owner
  -- toggled it off. Restart only what was running.
  vim.api.nvim_create_autocmd("DirChanged", {
    group = vim.api.nvim_create_augroup("harness_spec_watch", { clear = true }),
    callback = function()
      if not M.is_active() then
        return
      end
      M.stop()
      M.start()
    end,
  })
end

return M
