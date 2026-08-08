vim.opt.mouse = "a"
vim.o.mousemoveevent = true

vim.schedule(function()
  vim.opt.clipboard = "unnamedplus"

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
end)

vim.opt.number = true
vim.opt.signcolumn = "yes:3"
vim.opt.numberwidth = 4
vim.opt.fillchars:append({ eob = " ", diff = " " })

vim.opt.diffopt = {
  "algorithm:minimal",
  "closeoff",
  "context:12",
  "filler",
  "internal",
  "linematch:60",
}
vim.opt.cursorline = false
vim.opt.spell = true
vim.opt.fixeol = false
