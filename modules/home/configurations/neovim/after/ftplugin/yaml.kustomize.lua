-- Kustomize-specific settings (inherits from yaml.lua)
vim.cmd("runtime! ftplugin/yaml.lua")

-- Keymaps specific to Kustomize
Snacks.keymap.set("n", "<localleader>b", function()
  vim.cmd("split | term kubectl kustomize .")
end, { ft = "yaml.kustomize", desc = "Build" })

Snacks.keymap.set("n", "<localleader>a", function()
  vim.cmd("split | term kubectl apply -k .")
end, { ft = "yaml.kustomize", desc = "Apply" })

Snacks.keymap.set("n", "<localleader>d", function()
  vim.cmd("split | term kubectl diff -k .")
end, { ft = "yaml.kustomize", desc = "Diff" })
