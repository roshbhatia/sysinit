-- Nushell specific settings and keymaps

-- Formatting
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true
vim.opt_local.commentstring = "# %s"

-- Keymaps
local map = vim.keymap.set
local opts = { buffer = true, silent = true }

-- Run current script
map("n", "<localleader>sr", function()
  local file = vim.fn.expand("%:p")
  vim.cmd("split | term nu " .. vim.fn.shellescape(file))
end, vim.tbl_extend("force", opts, { desc = "Nushell: Run script" }))

-- Open in Nushell REPL
map("n", "<localleader>sr", function()
  vim.cmd("split | term nu")
end, vim.tbl_extend("force", opts, { desc = "Nushell: Open REPL" }))
