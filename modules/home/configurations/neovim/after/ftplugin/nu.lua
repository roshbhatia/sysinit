vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true
vim.opt_local.commentstring = "# %s"

-- Keymaps
Snacks.keymap.set("n", "<localleader>r", function()
  local file = vim.fn.expand("%:p")
  vim.cmd("split | term nu " .. vim.fn.shellescape(file))
end, { ft = "nu", desc = "Run script" })

Snacks.keymap.set("n", "<localleader>i", function()
  vim.cmd("split | term nu")
end, { ft = "nu", desc = "Open REPL" })
