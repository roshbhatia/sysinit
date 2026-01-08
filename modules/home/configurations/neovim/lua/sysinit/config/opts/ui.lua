local M = {}

function M.setup()
  vim.opt.laststatus = 3
  vim.opt.shortmess:append("sIWc")
  vim.opt.showmode = false
  vim.opt.showtabline = 0
  vim.opt.splitkeep = "topline"
  vim.opt.termguicolors = true
end

return M
