-- YAML-specific settings and keymaps

-- Formatting
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true
vim.opt_local.foldmethod = "indent"
vim.opt_local.foldlevel = 99

-- Keymaps
local map = vim.keymap.set
local opts = { buffer = true, silent = true }

-- YAML schema selection
map(
  "n",
  "<localleader>ys",
  "<cmd>Telescope yaml_schema<cr>",
  vim.tbl_extend("force", opts, { desc = "YAML: Select schema" })
)

-- Kubernetes-specific helpers (when in k8s files)
local filename = vim.fn.expand("%:t")
if filename:match("%.ya?ml$") and (vim.fn.expand("%:p"):match("/k8s/") or filename:match("kustomization")) then
  -- Quick navigation between manifests
  map("n", "]k", "/^---\\s*$<cr>:nohl<cr>", vim.tbl_extend("force", opts, { desc = "YAML: Next Kubernetes resource" }))
  map(
    "n",
    "[k",
    "?^---\\s*$<cr>:nohl<cr>",
    vim.tbl_extend("force", opts, { desc = "YAML: Previous Kubernetes resource" })
  )
end
