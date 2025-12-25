local M = {}

function M.setup()
  vim.o.ignorecase = true
  vim.opt.hlsearch = false
  vim.opt.inccommand = "nosplit"
  vim.opt.incsearch = true
end

return M
