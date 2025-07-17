local M = {}

function M.setup()
	if vim.fn.argc() > 0 and vim.fn.isdirectory(vim.fn.expand(vim.fn.argv()[1])) == 1 then
		Snacks.dashboard()
	end
end

return M
