local M = {}

function M.setup()
	vim.keymap.set("n", "<leader>q", "<CMD>qa!<CR>", {
		noremap = true,
		silent = true,
		desc = "Quit",
	})

	vim.keymap.set("i", "jj", "<ESC>", {
		noremap = true,
		silent = true,
		desc = "Escape Insert Mode",
	})
end

return M
