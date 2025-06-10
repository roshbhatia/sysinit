local M = {}

function M.setup()
	vim.opt.termguicolors = true
	vim.opt.showmode = true
	vim.o.showtabline = 0
	vim.opt.laststatus = 3
end

return M
