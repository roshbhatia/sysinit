-- Formatting
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

-- JSON-specific options
vim.opt_local.conceallevel = 0 -- Show quotes

-- Keymaps
local map = vim.keymap.set
local opts = { buffer = true, silent = true }

-- Format JSON
map("n", "<localleader>jf", ":%!jq .<cr>", vim.tbl_extend("force", opts, { desc = "JSON: Format with jq" }))
map("v", "<localleader>jf", ":!jq .<cr>", vim.tbl_extend("force", opts, { desc = "JSON: Format selection with jq" }))

-- Compact JSON
map("n", "<localleader>jc", ":%!jq -c .<cr>", vim.tbl_extend("force", opts, { desc = "JSON: Compact with jq" }))

-- Sort JSON keys
map("n", "<localleader>js", ":%!jq -S .<cr>", vim.tbl_extend("force", opts, { desc = "JSON: Sort keys with jq" }))

-- Validate JSON
map("n", "<localleader>jv", "<cmd>!jq empty %<cr>", vim.tbl_extend("force", opts, { desc = "JSON: Validate syntax" }))

-- Copy JSON path under cursor (if supported by LSP/plugin)
-- This would typically be provided by a JSON-specific plugin like "jsonls"
