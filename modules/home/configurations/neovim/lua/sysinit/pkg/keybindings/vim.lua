local M = {}

function M.setup()
	vim.keymap.set("n", "<leader>q", "<CMD>qa!<CR>", {
		noremap = true,
		silent = true,
		desc = "Quit",
	})
end

return M
