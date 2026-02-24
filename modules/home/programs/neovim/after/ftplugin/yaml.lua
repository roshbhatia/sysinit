vim.opt_local.foldlevel = 99

-- Validation via :make (yq validates YAML by attempting to parse it)
vim.opt_local.makeprg = "yq . % > /dev/null"
vim.opt_local.errorformat = [[%EError: bad file '%f': yaml: line %l: %m,%-G%.%#]]

Snacks.keymap.set("n", "<localleader>xf", ":%!yq -P .<cr>", { ft = "yaml", desc = "Format with yq" })
Snacks.keymap.set("v", "<localleader>xf", ":!yq -P .<cr>", { ft = "yaml", desc = "Format selection with yq" })

Snacks.keymap.set("n", "<localleader>xc", ":%!yq -c .<cr>", { ft = "yaml", desc = "Compact sequences with yq" })

Snacks.keymap.set("n", "<localleader>xv", "<cmd>make<cr>", { ft = "yaml", desc = "Validate syntax" })
