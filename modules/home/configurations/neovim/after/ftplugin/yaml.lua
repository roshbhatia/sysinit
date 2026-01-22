vim.opt_local.foldlevel = 99

Snacks.keymap.set("n", "<localleader>s", "<cmd>Telescope yaml_schema<cr>", { ft = "yaml", desc = "Select schema" })
