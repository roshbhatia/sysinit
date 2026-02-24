vim.cmd("compiler go")
vim.opt_local.makeprg = "go build ./..."
vim.opt_local.errorformat = "%f:%l:%c: %m"

Snacks.keymap.set("n", "<localleader>xt", "<cmd>gotestfile<cr>", { ft = "go", desc = "Run tests in file" })
Snacks.keymap.set("n", "<localleader>xT", "<cmd>GoTestPkg<cr>", { ft = "go", desc = "Run tests in package" })
Snacks.keymap.set("n", "<localleader>xta", "<cmd>GoAddTag<cr>", { ft = "go", desc = "Add struct tags" })
Snacks.keymap.set("n", "<localleader>xtr", "<cmd>GoRmTag<cr>", { ft = "go", desc = "Remove struct tags" })
Snacks.keymap.set("n", "<localleader>xi", "<cmd>GoImpl<cr>", { ft = "go", desc = "Generate implementation" })
Snacks.keymap.set("n", "<localleader>xf", "<cmd>GoFillStruct<cr>", { ft = "go", desc = "Fill struct" })
Snacks.keymap.set("n", "<localleader>xe", "<cmd>GoIfErr<cr>", { ft = "go", desc = "Add if err check" })
