local M = {}

local state = { job = nil, path = nil }
local configured = false

local function running()
  return state.job ~= nil and vim.fn.jobwait({ state.job }, 0)[1] == -1
end

function M.stop()
  if running() then
    pcall(vim.fn.jobstop, state.job)
  end
  state.job, state.path = nil, nil
end

function M.toggle_browser()
  M.setup()
  if vim.fn.executable("go-grip") == 0 then
    vim.notify("go-grip is not on PATH", vim.log.levels.ERROR)
    return
  end
  local path = vim.fn.expand("%:p")
  if path == "" or vim.fn.filereadable(path) == 0 then
    vim.notify("markdown preview: save the buffer first", vim.log.levels.WARN)
    return
  end

  if state.path == path and running() then
    M.stop()
    vim.notify("markdown preview: stopped")
    return
  end
  M.stop()

  state.job = vim.fn.jobstart({ "go-grip", "-b", path }, { detach = false })
  if state.job <= 0 then
    state.job = nil
    vim.notify("markdown preview: go-grip failed to start", vim.log.levels.ERROR)
    return
  end
  state.path = path
end

function M.toggle_glow()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("markdown preview: buffer has no file", vim.log.levels.WARN)
    return
  end
  local res = require("harness.preview").open(path, { focus = false })
  if not res.ok then
    vim.notify("markdown preview: " .. tostring(res.error), vim.log.levels.WARN)
  end
end

function M.setup()
  if configured then
    return
  end
  configured = true
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("SysinitGoGrip", { clear = true }),
    callback = M.stop,
  })
end

return M
