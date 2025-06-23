local M = {}

M.plugins = {
	{
		"shellRaining/hlchunk.nvim",
		event = {
			"VeryLazy",
		},
		config = function()
			require("hlchunk").setup({
				chunk = {
					enable = true,
					use_treesitter = true,
					duration = 100,
					delay = 100,
				},
				indent = {
					enable = false,
				},
				blank = {
					enable = false,
				},
				line_num = {
					enable = false,
				},
			})
		end,
	},
}

return M

