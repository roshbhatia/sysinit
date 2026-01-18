-- Kustomize-specific settings (inherits from yaml.lua)
vim.cmd("runtime! ftplugin/yaml.lua")

-- Keymaps specific to Kustomize
local map = vim.keymap.set
local opts = { buffer = true, silent = true }

-- Build kustomization
map("n", "<localleader>kb", function()
  vim.cmd("split | term kubectl kustomize .")
end, vim.tbl_extend("force", opts, { desc = "Kustomize: Build" }))

-- Apply kustomization
map("n", "<localleader>ka", function()
  vim.cmd("split | term kubectl apply -k .")
end, vim.tbl_extend("force", opts, { desc = "Kustomize: Apply" }))

-- Diff kustomization
map("n", "<localleader>kd", function()
  vim.cmd("split | term kubectl diff -k .")
end, vim.tbl_extend("force", opts, { desc = "Kustomize: Diff" }))
