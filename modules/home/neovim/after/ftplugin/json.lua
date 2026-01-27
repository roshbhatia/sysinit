vim.opt_local.expandtab = true
vim.opt_local.conceallevel = 0 -- Show quotes

-- Validation via :make
vim.opt_local.makeprg = "jq empty %"
vim.opt_local.errorformat = "jq: parse error: %m at line %l\\, column %c"

Snacks.keymap.set("n", "<localleader>f", ":%!jq .<cr>", { ft = "json", desc = "Format with jq" })
Snacks.keymap.set("v", "<localleader>f", ":!jq .<cr>", { ft = "json", desc = "Format selection with jq" })

Snacks.keymap.set("n", "<localleader>c", ":%!jq -c .<cr>", { ft = "json", desc = "Compact with jq" })

Snacks.keymap.set("n", "<localleader>s", ":%!jq -S .<cr>", { ft = "json", desc = "Sort keys with jq" })

Snacks.keymap.set("n", "<localleader>v", "<cmd>make<cr>", { ft = "json", desc = "Validate syntax" })
