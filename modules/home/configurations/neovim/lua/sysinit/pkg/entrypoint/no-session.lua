local M = {}

function M.setup()
	if vim.fn.argc() > 0 and vim.fn.isdirectory(vim.fn.expand(vim.fn.argv()[1])) == 1 then
		vim.cmd("Alpha")
	end
end

return M

