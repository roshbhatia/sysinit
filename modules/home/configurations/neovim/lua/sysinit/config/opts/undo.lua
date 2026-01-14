local M = {}

function M.setup()
  local undodir = vim.fn.stdpath("cache") .. "/undo"
  vim.fn.mkdir(undodir, "p")
  vim.opt.undodir = undodir

  vim.opt.undofile = true
  vim.opt.undolevels = 1000
end

return M
