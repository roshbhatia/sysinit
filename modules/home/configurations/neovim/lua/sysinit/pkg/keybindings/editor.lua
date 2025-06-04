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
		desc = "Editor: Toggle line number display",
	})

	vim.keymap.set("n", "<D-a>", "ggVG")
end

return M

