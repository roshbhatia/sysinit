-- The two markdown previews, as a module rather than as a lazy plugin spec.
--
-- This was `lua/plugins/markdown-preview.lua`, which declared no plugin: it returned
-- an empty spec and did its work as a load side effect, so lazy.nvim carried it for
-- nothing and the keymap existed in every filetype. The keymaps now live in
-- `after/ftplugin/markdown.lua`, where they apply to the buffers they mean something
-- in, and the state lives here, where `require` caches it once instead of rebuilding
-- it per markdown buffer.
local M = {}

local state = { job = nil, path = nil }

local function running()
  return state.job ~= nil and vim.fn.jobwait({ state.job }, 0)[1] == -1
end

function M.stop()
  if running() then
    pcall(vim.fn.jobstop, state.job)
  end
  state.job, state.path = nil, nil
end

--- Toggle the go-grip browser preview of the current buffer.
---
--- go-grip renders through a local server, so it needs a file on disk rather than the
--- buffer's lines.
function M.toggle_browser()
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

--- Toggle the glow terminal preview of the current buffer.
---
--- `harness.preview` rather than a bare `Snacks.terminal.toggle`, because it renders
--- into a wezterm split when nvim runs in one and falls back to snacks otherwise. It
--- was reachable only as `<leader>jp`, a global key for a markdown-only action.
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

-- Registered once, at require time, so a second markdown buffer does not add a
-- second teardown for the same job.
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("SysinitGoGrip", { clear = true }),
  callback = M.stop,
})

return M
