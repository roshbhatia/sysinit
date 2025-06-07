local M = {}

M.plugins = {
	{
		"shellRaining/hlchunk.nvim",
		commit = "474ec5d0f220158afa83aaefab32402e710d3032",
		event = { "VeryLazy" },
		config = function()
			require("hlchunk").setup({
				chunk = {
					enable = true,
					use_treesitter = true,
				},
				indent = {
					enable = false,
				},
				blank = {
					enable = false,
				},
				line_num = {
					enable = true,
				},
			})
		end,
	},
}

return M

