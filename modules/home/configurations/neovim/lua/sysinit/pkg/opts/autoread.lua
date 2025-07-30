local M = {}

function M.setup()
  vim.opt.shortmess:append("A")
  vim.o.autoread = true
end

return M
