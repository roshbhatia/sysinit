-- Helm-specific settings and keymaps

-- Formatting (YAML-based)
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true
vim.opt_local.foldmethod = "indent"
vim.opt_local.foldlevel = 99

-- Comment string for Helm (supports both YAML and Go template comments)
vim.opt_local.commentstring = "{{/* %s */}}"

-- Keymaps
local map = vim.keymap.set
local opts = { buffer = true, silent = true }

-- Helm template actions
map(
  "n",
  "<localleader>ht",
  "<cmd>!helm template .<cr>",
  vim.tbl_extend("force", opts, { desc = "Helm: Template chart" })
)
map("n", "<localleader>hl", "<cmd>!helm lint .<cr>", vim.tbl_extend("force", opts, { desc = "Helm: Lint chart" }))

-- Quick navigation between Helm resources (similar to k8s)
map("n", "]k", "/^---\\s*$<cr>:nohl<cr>", vim.tbl_extend("force", opts, { desc = "Helm: Next resource" }))
map("n", "[k", "?^---\\s*$<cr>:nohl<cr>", vim.tbl_extend("force", opts, { desc = "Helm: Previous resource" }))

-- Insert common Helm template expressions
map(
  "n",
  "<localleader>hv",
  "i{{ .Values. }}<Esc>",
  vim.tbl_extend("force", opts, { desc = "Helm: Insert Values reference" })
)
map(
  "n",
  "<localleader>hr",
  "i{{ .Release. }}<Esc>",
  vim.tbl_extend("force", opts, { desc = "Helm: Insert Release reference" })
)
map(
  "n",
  "<localleader>hc",
  "i{{ .Chart. }}<Esc>",
  vim.tbl_extend("force", opts, { desc = "Helm: Insert Chart reference" })
)
