vim.opt_local.conceallevel = 0

vim.opt_local.makeprg = "jq empty %"
vim.opt_local.errorformat = "jq: parse error: %m at line %l\\, column %c"

Snacks.keymap.set("n", "<localleader>xf", ":%!jq .<cr>", { ft = "json", desc = "Format with jq" })
Snacks.keymap.set("v", "<localleader>xf", ":!jq .<cr>", { ft = "json", desc = "Format selection with jq" })

Snacks.keymap.set("n", "<localleader>xc", ":%!jq -c .<cr>", { ft = "json", desc = "Compact with jq" })

Snacks.keymap.set("n", "<localleader>xs", ":%!jq -S .<cr>", { ft = "json", desc = "Sort keys with jq" })

Snacks.keymap.set("n", "<localleader>xv", "<cmd>make<cr>", { ft = "json", desc = "Validate syntax" })
