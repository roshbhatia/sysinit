local M = {}

function M.setup()
	vim.keymap.set("n", "<leader>en", function()
		if vim.wo.relativenumber then
			vim.wo.relativenumber = false
			vim.wo.number = true
		else
			vim.wo.relativenumber = true
			vim.wo.number = true
		end
	end, {
		noremap = true,
		silent = true,
		desc = "Toggle line number display",
	})

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

	vim.keymap.set("v", "<leader>rx", '"+x', {
		noremap = true,
		silent = true,
		desc = "Cut selection",
	})

	vim.keymap.set("n", "<leader>rp", "p", {
		noremap = true,
		silent = true,
		desc = "Paste clipboard contents",
	})

	vim.keymap.set("n", "<leader>rr", "<cmd>edit<cr>", {
		noremap = true,
		silent = true,
		desc = "Refresh buffer",
	})
end

return M

