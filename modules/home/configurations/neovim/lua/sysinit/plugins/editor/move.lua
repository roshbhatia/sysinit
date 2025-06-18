local M = {}

M.plugins = {
	{
		"echasnovski/mini.move",
		version = "*",
		config = function()
			require("mini.move").setup({
				mappings = {
					left = "<C-M-h>",
					right = "<C-M-l>",
					down = "<C-M-j>",
					up = "<C-M-k>",

					line_left = "<C-M-h>",
					line_right = "<C-M-l>",
					line_down = "<C-M-j>",
					line_up = "<C-M-k>",
				},
				options = {
					reindent_linewise = true,
				},
			})
		end,
	},
}

return M

