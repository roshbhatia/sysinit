local M = {}

function M.setup()
	vim.keymap.set("n", "<leader>q", "<CMD>qa!<CR>", {
		noremap = true,
		silent = true,
		desc = "Quit",
	})

	vim.keymap.set("n", "<localleader>L", "<CMD>Lazy<CR>", {
		noremap = true,
		silent = true,
		desc = "Lazy",
	})
end

return M
