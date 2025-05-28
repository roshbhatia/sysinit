local M = {}

function M.setup()
	local undodir = vim.fn.stdpath("cache") .. "/undo"
	if vim.fn.isdirectory(undodir) == 0 then
		vim.fn.mkdir(undodir, "p")
	end
	vim.opt.undodir = undodir
	vim.opt.undofile = true
end

return M
