local M = {}

function M.setup()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "help",
		command = "wincmd L",
	})
end

return M
