local M = {}

function M.setup()
  vim.opt.laststatus = 3
  vim.opt.showtabline = 2
  vim.opt.shortmess:append("sIWc")
  vim.opt.showmode = false
  vim.opt.termguicolors = true
  vim.opt.winblend = 0
  vim.opt.pumblend = 0
  vim.opt.splitkeep = "topline"
end

return M
