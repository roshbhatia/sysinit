local M = {}

function M.setup()
	vim.opt.foldenable = true
	vim.opt.foldlevel = 99
	vim.wo.foldmethod = "expr"
	vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
	vim.opt.fillchars:append({ fold = " " })
end

return M

