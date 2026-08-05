vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
