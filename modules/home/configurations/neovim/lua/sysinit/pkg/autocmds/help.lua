local M = {}

function M.setup()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "help",
		command = "wincmd L",
	})

	-- Force refresh the buffer on BufEnter
	vim.api.nvim_create_autocmd("BufEnter", {
		command = "edit",
	})
end

return M

