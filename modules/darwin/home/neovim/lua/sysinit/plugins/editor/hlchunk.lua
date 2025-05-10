local M = {}

M.plugins = {
	{
		"shellRaining/hlchunk.nvim",
		event = { "VeryLazy" },
		config = function()
			require("hlchunk").setup({
				chunk = {
					enable = true,
				},
				indent = {
					enable = false,
				},
				blank = {
					enable = false,
				},
				line_num = {
					enablechunk = true,
					use_treesitter = true,
				},
			})
		end,
	},
}

return M

