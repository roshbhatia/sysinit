local M = {}

function M.setup()
	vim.opt.hlsearch = true
	vim.opt.incsearch = true
	vim.opt.ignorecase = true
	vim.opt.inccommand = "nosplit"
end

return M
