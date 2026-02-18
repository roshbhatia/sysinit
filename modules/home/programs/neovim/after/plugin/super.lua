Snacks.keymap.set("n", "<leader><leader>", ":", { desc = "Command" })

Snacks.keymap.set("n", "<leader>x", function()
  vim.cmd("silent! qa!")
end, { desc = "Force quit" })
