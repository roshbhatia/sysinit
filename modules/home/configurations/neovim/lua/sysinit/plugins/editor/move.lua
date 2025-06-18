local M = {}

M.plugins = {
	{
		"echasnovski/mini.move",
		version = "*",
		config = function()
			require("mini.move").setup({
				mappings = {
					left = "<C-A-h>",
					right = "<C-A-l>",
					down = "<C-A-j>",
					up = "<C-A-k>",

					line_left = "<C-A-h>",
					line_right = "<C-A-l>",
					line_down = "<C-A-j>",
					line_up = "<C-A-k>",
				},
				options = {
					reindent_linewise = true,
				},
			})
		end,
	},
}

return M

