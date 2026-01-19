vim.keymap.set("n", "<leader><leader>", ":", { desc = "Command" })

vim.keymap.set("n", "<leader>x", function()
  vim.cmd("silent! qa!")
end, {
  noremap = true,
  silent = true,
  desc = "Force quit",
})
