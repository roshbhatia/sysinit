-- YAML-specific settings and keymaps

-- Formatting
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true
vim.opt_local.foldmethod = "indent"
vim.opt_local.foldlevel = 99

-- Keymaps
Snacks.keymap.set("n", "<localleader>s", "<cmd>Telescope yaml_schema<cr>", { ft = "yaml", desc = "Select schema" })

-- Kubernetes-specific helpers (when in k8s files)
local filename = vim.fn.expand("%:t")
if filename:match("%.ya?ml$") and (vim.fn.expand("%:p"):match("/k8s/") or filename:match("kustomization")) then
  -- Quick navigation between manifests
  Snacks.keymap.set("n", "]k", "/^---\\s*$<cr>:nohl<cr>", { ft = "yaml", desc = "Next Kubernetes resource" })
  Snacks.keymap.set("n", "[k", "?^---\\s*$<cr>:nohl<cr>", { ft = "yaml", desc = "Previous Kubernetes resource" })
end
