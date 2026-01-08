local M = {}

function M.setup()
  vim.opt.laststatus = 3
  vim.opt.pumblend = 15
  vim.opt.winblend = 0
  vim.opt.shortmess:append("sIWc")
  vim.opt.showmode = false
  vim.opt.showtabline = 0
  vim.opt.sidescrolloff = 0
  vim.opt.splitkeep = "topline"
  vim.opt.termguicolors = true
end

return M
