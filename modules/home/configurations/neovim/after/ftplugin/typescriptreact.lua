-- TypeScript React (TSX) specific settings and keymaps

-- Formatting
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

-- Keymaps
Snacks.keymap.set("n", "<localleader>s", "<cmd>!npm start<cr>", { ft = "typescriptreact", desc = "Start dev server" })
Snacks.keymap.set(
  "n",
  "<localleader>b",
  "<cmd>!npm run build<cr>",
  { ft = "typescriptreact", desc = "Build production" }
)

-- Testing
Snacks.keymap.set(
  "n",
  "<localleader>t",
  "<cmd>!npm test -- %<cr>",
  { ft = "typescriptreact", desc = "Run tests for file" }
)
Snacks.keymap.set("n", "<localleader>T", "<cmd>!npm test<cr>", { ft = "typescriptreact", desc = "Run all tests" })

-- Component navigation helpers
Snacks.keymap.set("n", "]i", "/^import<cr>:nohl<cr>", { ft = "typescriptreact", desc = "Next import" })
Snacks.keymap.set("n", "[i", "?^import<cr>:nohl<cr>", { ft = "typescriptreact", desc = "Previous import" })

-- TypeScript-specific LSP actions (will be available when LSP attaches)
-- These are handled by LSP in utils/lsp/keymaps.lua
