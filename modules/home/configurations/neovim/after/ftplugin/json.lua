vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

-- JSON-specific options
vim.opt_local.conceallevel = 0 -- Show quotes

-- Keymaps
Snacks.keymap.set("n", "<localleader>f", ":%!jq .<cr>", { ft = "json", desc = "Format with jq" })
Snacks.keymap.set("v", "<localleader>f", ":!jq .<cr>", { ft = "json", desc = "Format selection with jq" })

-- Compact JSON
Snacks.keymap.set("n", "<localleader>c", ":%!jq -c .<cr>", { ft = "json", desc = "Compact with jq" })

-- Sort JSON keys
Snacks.keymap.set("n", "<localleader>s", ":%!jq -S .<cr>", { ft = "json", desc = "Sort keys with jq" })

-- Validate JSON
Snacks.keymap.set("n", "<localleader>v", "<cmd>!jq empty %<cr>", { ft = "json", desc = "Validate syntax" })
