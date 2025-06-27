local M = {}

function M.setup()
	vim.o.showtabline = 0
	vim.opt.laststatus = 3
	vim.opt.shortmess:append("sI")
	vim.opt.showmode = false
	vim.opt.termguicolors = true
	vim.opt.winblend = 0
end

return M
