-- TypeScript React (TSX) specific settings and keymaps

-- Formatting
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

-- Keymaps
local map = vim.keymap.set
local opts = { buffer = true, silent = true }

-- Development server (common React patterns)
map("n", "<localleader>rs", "<cmd>!npm start<cr>", vim.tbl_extend("force", opts, { desc = "React: Start dev server" }))
map(
  "n",
  "<localleader>rb",
  "<cmd>!npm run build<cr>",
  vim.tbl_extend("force", opts, { desc = "React: Build production" })
)

-- Testing
map(
  "n",
  "<localleader>rt",
  "<cmd>!npm test -- %<cr>",
  vim.tbl_extend("force", opts, { desc = "React: Run tests for file" })
)
map("n", "<localleader>rT", "<cmd>!npm test<cr>", vim.tbl_extend("force", opts, { desc = "React: Run all tests" }))

-- Component navigation helpers
-- Jump to import statements
map("n", "]i", "/^import<cr>:nohl<cr>", vim.tbl_extend("force", opts, { desc = "React: Next import" }))
map("n", "[i", "?^import<cr>:nohl<cr>", vim.tbl_extend("force", opts, { desc = "React: Previous import" }))

-- TypeScript-specific LSP actions (will be available when LSP attaches)
-- These are handled by LSP in utils/lsp/keymaps.lua
