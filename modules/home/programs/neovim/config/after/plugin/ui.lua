vim.opt.laststatus = 3
vim.opt.shortmess:append("sIWc")
vim.opt.showmode = false
vim.opt.showtabline = 2
vim.opt.sidescrolloff = 0
vim.opt.splitkeep = "screen"
vim.opt.termguicolors = true

Snacks.keymap.set("n", "<leader>v", function()
  vim.cmd("vsplit")
end, {
  desc = "Split pane vertically",
})

Snacks.keymap.set("n", "<leader>s", function()
  vim.cmd("split")
end, {
  desc = "Split pane horizontally",
})
