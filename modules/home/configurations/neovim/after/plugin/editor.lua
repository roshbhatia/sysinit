vim.opt.mouse = "a"
vim.o.mousemoveevent = true
vim.opt.clipboard = "unnamedplus"

-- https://github.com/tjdevries/config.nvim/blob/master/plugin/clipboard.lua
if vim.env.SSH_CONNECTION then
  local function vim_paste()
    local content = vim.fn.getreg('"')
    return vim.split(content, "\n")
  end

  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = vim_paste,
      ["*"] = vim_paste,
    },
  }
end

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes:3"
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
vim.opt.spell = true
vim.opt.fixeol = false
