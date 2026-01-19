-- TypeScript-specific settings and keymaps

-- Formatting
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

-- Keymaps
local map = vim.keymap.set
local opts = { buffer = true, silent = true }

-- TypeScript execution (via ts-node if available)
map(
  "n",
  "<localleader>tr",
  "<cmd>!ts-node %<cr>",
  vim.tbl_extend("force", opts, { desc = "TypeScript: Run with ts-node" })
)

-- Build/compile
map("n", "<localleader>tb", "<cmd>!tsc %<cr>", vim.tbl_extend("force", opts, { desc = "TypeScript: Compile file" }))
map("n", "<localleader>tB", "<cmd>!tsc<cr>", vim.tbl_extend("force", opts, { desc = "TypeScript: Build project" }))

-- Testing (assuming jest/vitest)
map(
  "n",
  "<localleader>tt",
  "<cmd>!npm test -- %<cr>",
  vim.tbl_extend("force", opts, { desc = "TypeScript: Run tests for file" })
)
map("n", "<localleader>tT", "<cmd>!npm test<cr>", vim.tbl_extend("force", opts, { desc = "TypeScript: Run all tests" }))

-- TypeScript-specific LSP actions (will be available when LSP attaches)
-- Organize imports - this is handled by LSP in utils/lsp/keymaps.lua
-- Add missing imports - this is handled by LSP code actions
