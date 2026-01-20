vim.opt_local.expandtab = false
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4

Snacks.keymap.set("n", "<localleader>t", "<cmd>gotestfile<cr>", { ft = "go", desc = "Run tests in file" })
Snacks.keymap.set("n", "<localleader>T", "<cmd>GoTestPkg<cr>", { ft = "go", desc = "Run tests in package" })
Snacks.keymap.set("n", "<localleader>ta", "<cmd>GoAddTag<cr>", { ft = "go", desc = "Add struct tags" })
Snacks.keymap.set("n", "<localleader>tr", "<cmd>GoRmTag<cr>", { ft = "go", desc = "Remove struct tags" })
Snacks.keymap.set("n", "<localleader>i", "<cmd>GoImpl<cr>", { ft = "go", desc = "Generate implementation" })
Snacks.keymap.set("n", "<localleader>f", "<cmd>GoFillStruct<cr>", { ft = "go", desc = "Fill struct" })
Snacks.keymap.set("n", "<localleader>e", "<cmd>GoIfErr<cr>", { ft = "go", desc = "Add if err check" })

vim.opt_local.errorformat = "%f:%l:%c: %m"
