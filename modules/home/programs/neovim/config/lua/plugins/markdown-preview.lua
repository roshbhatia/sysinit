
local state = { job = nil, path = nil }

local function stop()
  if state.job and vim.fn.jobwait({ state.job }, 0)[1] == -1 then
    pcall(vim.fn.jobstop, state.job)
  end
  state.job, state.path = nil, nil
end

local function toggle()
  if vim.fn.executable("go-grip") == 0 then
    vim.notify("go-grip is not on PATH", vim.log.levels.ERROR)
    return
  end
  local path = vim.fn.expand("%:p")
  if path == "" or vim.fn.filereadable(path) == 0 then
    vim.notify("markdown preview: save the buffer first", vim.log.levels.WARN)
    return
  end

  if state.job and state.path == path and vim.fn.jobwait({ state.job }, 0)[1] == -1 then
    stop()
    vim.notify("markdown preview: stopped")
    return
  end
  stop()

  state.job = vim.fn.jobstart({ "go-grip", "-b", path }, { detach = false })
  if state.job <= 0 then
    state.job = nil
    vim.notify("markdown preview: go-grip failed to start", vim.log.levels.ERROR)
    return
  end
  state.path = path
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("SysinitGoGrip", { clear = true }),
  callback = stop,
})

vim.keymap.set("n", "<localleader>xP", toggle, { desc = "Toggle markdown preview (go-grip)" })

return {}
