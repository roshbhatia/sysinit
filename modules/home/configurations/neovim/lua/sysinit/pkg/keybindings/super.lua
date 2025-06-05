local M = {}

function M.setup()
	vim.keymap.set("n", "<leader>ra", "ggVG", {
		noremap = true,
		silent = true,
		desc = "Select all",
	})

	vim.keymap.set("v", "<leader>rc", '"+y', {
		noremap = true,
		silent = true,
		desc = "Copy selection",
	})

	vim.keymap.set("v", "<leader>rx", "d", {
		noremap = true,
		silent = true,
		desc = "Cut selection",
	})

	vim.keymap.set("n", "<leader>rp", "p", {
		noremap = true,
		silent = true,
		desc = "Paste",
	})

	vim.keymap.set("n", "<leader>rr", "<CMD>edit<CR>", {
		noremap = true,
		silent = true,
		desc = "Refresh",
	})
end

return M
