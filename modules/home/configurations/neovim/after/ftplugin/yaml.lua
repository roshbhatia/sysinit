vim.opt_local.foldlevel = 99

-- Validation via :make (yq validates YAML by attempting to parse it)
vim.opt_local.makeprg = "yq . % > /dev/null"
vim.opt_local.errorformat = [[%Ein "%f"\, line %l\, column %c.,%-G%.%#]]

Snacks.keymap.set("n", "<localleader>s", "<cmd>Telescope yaml_schema<cr>", { ft = "yaml", desc = "Select schema" })
Snacks.keymap.set("n", "<localleader>v", "<cmd>make<cr>", { ft = "yaml", desc = "Validate syntax" })
