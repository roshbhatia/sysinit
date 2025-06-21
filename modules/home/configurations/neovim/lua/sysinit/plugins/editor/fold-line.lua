local M = {}

M.plugins = {
	{
		"gh-liu/fold_line.nvim",
		event = "VeryLazy",
		init = function()
			vim.g.fold_line_char_open_start = "╭"
			vim.g.fold_line_char_open_end = "╰"
		end,
	},
}

return M

