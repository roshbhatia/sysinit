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
vim.opt.signcolumn = "yes:3"
vim.opt.numberwidth = 4
vim.opt.fillchars:append({ eob = " ", diff = " " })

-- Base diffopt options
local diffopt = {
  "algorithm:minimal",
  "closeoff",
  "context:12",
  "filler",
  "internal",
}

-- Add newer options if available (Neovim 0.9+)
if vim.fn.has("nvim-0.9") == 1 then
  table.insert(diffopt, "linematch:60")
end

vim.opt.diffopt = diffopt
vim.opt.cursorline = false
vim.opt.spell = true
vim.opt.fixeol = false
