local M = {}

function M.setup()
  vim.opt.mouse = "a"
  vim.o.mousemoveevent = true
  vim.opt.clipboard = "unnamedplus"
  vim.opt.number = true
  vim.opt.relativenumber = true
  vim.opt.signcolumn = "yes:2"
  vim.opt.numberwidth = 4
  vim.opt.fillchars:append({ eob = " ", diff = " " })
  vim.opt.diffopt = {
    "internal",
    "filler",
    "closeoff",
    "context:12",
    "algorithm:histogram",
    "linematch:200",
  }
  vim.opt.cursorline = false
  vim.opt.spell = false
  vim.opt.fixeol = false
end

return M
