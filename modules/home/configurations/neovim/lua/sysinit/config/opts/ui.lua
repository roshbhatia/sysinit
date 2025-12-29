local M = {}

function M.setup()
  vim.opt.laststatus = 3
  vim.opt.pumblend = 0
  vim.opt.shortmess:append("sIWc")
  vim.opt.showmode = false
  vim.opt.showtabline = 0
  vim.opt.splitkeep = "topline"
  vim.opt.termguicolors = true
  vim.opt.winblend = 0
end

return M
