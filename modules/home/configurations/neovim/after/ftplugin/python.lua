-- Python-specific settings and keymaps

-- Formatting (PEP 8)
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.expandtab = true
vim.opt_local.textwidth = 88 -- Black formatter default
vim.opt_local.colorcolumn = "89"

-- Python-specific options
vim.opt_local.foldmethod = "indent"
vim.opt_local.foldlevel = 99

-- Keymaps
local map = vim.keymap.set
local opts = { buffer = true, silent = true }

-- Python execution
map("n", "<localleader>pr", "<cmd>!python3 %<cr>", vim.tbl_extend("force", opts, { desc = "Python: Run current file" }))
map("v", "<localleader>pr", ":!python3<cr>", vim.tbl_extend("force", opts, { desc = "Python: Run selection" }))

-- Testing (pytest)
map("n", "<localleader>pt", "<cmd>!pytest %<cr>", vim.tbl_extend("force", opts, { desc = "Python: Run tests in file" }))
map("n", "<localleader>pT", "<cmd>!pytest<cr>", vim.tbl_extend("force", opts, { desc = "Python: Run all tests" }))

-- Virtual environment
map(
  "n",
  "<localleader>pv",
  "<cmd>!python3 -m venv venv<cr>",
  vim.tbl_extend("force", opts, { desc = "Python: Create venv" })
)

-- Format with black (if available)
map("n", "<localleader>pf", "<cmd>!black %<cr>", vim.tbl_extend("force", opts, { desc = "Python: Format with black" }))

-- Imports
map(
  "n",
  "<localleader>pi",
  "<cmd>!isort %<cr>",
  vim.tbl_extend("force", opts, { desc = "Python: Sort imports with isort" })
)
