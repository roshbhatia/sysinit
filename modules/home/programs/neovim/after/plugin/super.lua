Snacks.keymap.set("n", "<leader><leader>", ":", { desc = "Command" })

Snacks.keymap.set("n", "<leader>qq", function()
  vim.cmd("silent! qa!")
end, { desc = "Force quit" })
