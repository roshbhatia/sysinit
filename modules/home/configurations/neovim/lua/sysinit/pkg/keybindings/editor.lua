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
		desc = "Toggle line numbers",
	})

	vim.keymap.set("n", "<localleader>ew", function()
		vim.wo.wrap = not vim.wo.wrap
	end, {
		noremap = true,
		silent = true,
		desc = "Toggle line wrapping",
	})
end

return M
