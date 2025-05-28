local M = {}

function M.setup()
	vim.opt.pumheight = 10
	vim.opt.cmdheight = 0
	vim.opt.cmdwinheight = 1
	vim.opt.laststatus = 3
	vim.opt.completeopt = { "menu", "menuone", "fuzzy", "preview" }
end

return M
