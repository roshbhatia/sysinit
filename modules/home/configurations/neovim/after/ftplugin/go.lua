vim.opt_local.expandtab = false
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4

local map = vim.keymap.set
local opts = { buffer = true, silent = true }

map("n", "<localleader>gt", "<cmd>GoTestFile<cr>", vim.tbl_extend("force", opts, { desc = "Go: Run tests in file" }))
map("n", "<localleader>gT", "<cmd>GoTestPkg<cr>", vim.tbl_extend("force", opts, { desc = "Go: Run tests in package" }))
map("n", "<localleader>gta", "<cmd>GoAddTag<cr>", vim.tbl_extend("force", opts, { desc = "Go: Add struct tags" }))
map("n", "<localleader>gtr", "<cmd>GoRmTag<cr>", vim.tbl_extend("force", opts, { desc = "Go: Remove struct tags" }))
map("n", "<localleader>gi", "<cmd>GoImpl<cr>", vim.tbl_extend("force", opts, { desc = "Go: Generate implementation" }))
map("n", "<localleader>gf", "<cmd>GoFillStruct<cr>", vim.tbl_extend("force", opts, { desc = "Go: Fill struct" }))
map("n", "<localleader>ge", "<cmd>GoIfErr<cr>", vim.tbl_extend("force", opts, { desc = "Go: Add if err check" }))

vim.opt_local.errorformat = "%f:%l:%c: %m"
