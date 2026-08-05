-- Instance registry for out-of-process agents.
--
-- When nvim spawns an agent pane it exports NVIM_HOST_SOCKET, so the agent
-- already knows where to reach us. The reverse case has no such env var: the
-- user starts an agent in a bare terminal, and only later wants an editor. For
-- that flow the agent has to *discover* a live nvim, so every instance drops a
-- record here and removes it on exit. This mirrors the lockfile claudecode.nvim
-- writes for its own bridge.
--
-- Consumers outside nvim (bin/nvim-ctl, the nvim-walkthrough skill) read this
-- directory directly, so the record shape is part of the contract.

local M = {}

---@return string
function M.dir()
  return vim.fs.joinpath(vim.fn.stdpath("state"), "harness", "instances")
end

local function record_path()
  return vim.fs.joinpath(M.dir(), tostring(vim.fn.getpid()) .. ".json")
end

---@return boolean
function M.register()
  local socket = vim.v.servername
  if not socket or socket == "" then
    return false
  end
  vim.fn.mkdir(M.dir(), "p")
  local record = {
    pid = vim.fn.getpid(),
    socket = socket,
    cwd = vim.fn.getcwd(),
    pane = vim.env.WEZTERM_PANE,
    started = os.time(),
  }
  local ok = pcall(vim.fn.writefile, { vim.json.encode(record) }, record_path())
  return ok
end

function M.unregister()
  pcall(vim.fn.delete, record_path())
end

--- Live records, with stale ones pruned as a side effect.
---@return table[]
function M.list()
  local out = {}
  local entries = vim.fn.glob(vim.fs.joinpath(M.dir(), "*.json"), false, true)
  for _, file in ipairs(entries) do
    local ok, lines = pcall(vim.fn.readfile, file)
    local decoded = ok and lines[1] and select(2, pcall(vim.json.decode, lines[1])) or nil
    -- A record whose socket is gone belongs to an nvim that died without
    -- running VimLeavePre (crash, SIGKILL). Drop it so discovery stays honest.
    local live = type(decoded) == "table" and decoded.socket and vim.uv.fs_stat(decoded.socket) ~= nil
    if live then
      table.insert(out, decoded)
    else
      pcall(vim.fn.delete, file)
    end
  end
  return out
end

function M.setup()
  local group = vim.api.nvim_create_augroup("harness_instance", { clear = true })
  M.register()
  vim.api.nvim_create_autocmd("DirChanged", {
    group = group,
    callback = function()
      M.register()
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      M.unregister()
    end,
  })
end

return M
