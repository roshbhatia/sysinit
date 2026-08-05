Snacks.keymap.set("n", "<leader><leader>", ":", { desc = "Command" })

vim.keymap.set("n", "q", "<Nop>", { desc = "Disable macro recording key" })

Snacks.keymap.set("n", "<leader>qq", function()
  vim.cmd("silent! qa!")
end, { desc = "Force quit" })
