vim.opt.laststatus = 3
vim.opt.pumblend = 15
vim.opt.shortmess:append("sIWc")
vim.opt.showmode = false
vim.opt.showtabline = 0
vim.opt.sidescrolloff = 0
vim.opt.splitkeep = "screen"
vim.opt.termguicolors = true
vim.opt.winblend = 0

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

if not vim.g.nix_managed then
  Snacks.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left pane" })
  Snacks.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom pane" })
  Snacks.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top pane" })
  Snacks.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right pane" })

  Snacks.keymap.set("n", "<C-S-h>", "<cmd>vertical resize -2<cr>", { desc = "Decrease pane width" })
  Snacks.keymap.set("n", "<C-S-j>", "<cmd>resize -2<cr>", { desc = "Decrease pane height" })
  Snacks.keymap.set("n", "<C-S-k>", "<cmd>resize +2<cr>", { desc = "Increase pane height" })
  Snacks.keymap.set("n", "<C-S-l>", "<cmd>vertical resize +2<cr>", { desc = "Increase pane width" })
end
