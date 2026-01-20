-- TypeScript-specific settings and keymaps

-- Formatting
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

-- Keymaps
Snacks.keymap.set("n", "<localleader>r", "<cmd>!ts-node %<cr>", { ft = "typescript", desc = "Run with ts-node" })

-- Build/compile
Snacks.keymap.set("n", "<localleader>b", "<cmd>!tsc %<cr>", { ft = "typescript", desc = "Compile file" })
Snacks.keymap.set("n", "<localleader>B", "<cmd>!tsc<cr>", { ft = "typescript", desc = "Build project" })

-- Testing (assuming jest/vitest)
Snacks.keymap.set("n", "<localleader>t", "<cmd>!npm test -- %<cr>", { ft = "typescript", desc = "Run tests for file" })
Snacks.keymap.set("n", "<localleader>T", "<cmd>!npm test<cr>", { ft = "typescript", desc = "Run all tests" })

-- TypeScript-specific LSP actions (will be available when LSP attaches)
-- Organize imports - this is handled by LSP in utils/lsp/keymaps.lua
-- Add missing imports - this is handled by LSP code actions
