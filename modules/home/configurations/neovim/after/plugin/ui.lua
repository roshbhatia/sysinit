vim.opt.laststatus = 3
vim.opt.pumblend = 15
vim.opt.winblend = 0
vim.opt.shortmess:append("sIWc")
vim.opt.showmode = false
vim.opt.showtabline = 0
vim.opt.sidescrolloff = 0
vim.opt.termguicolors = true

Snacks.keymap.set("n", "<leader>v", function()
  vim.cmd("vsplit")
end, {
  desc = "Split pane vertically",
})

-- Horizontal split
Snacks.keymap.set("n", "<leader>s", function()
  vim.cmd("split")
end, {
  desc = "Split pane horizontally",
})

Snacks.keymap.set("n", "<leader>w", function()
  vim.cmd("silent! xit")
end, {
  desc = "Close pane",
})
