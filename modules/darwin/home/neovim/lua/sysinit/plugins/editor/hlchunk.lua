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
				},
			})
		end,
	},
}

return M

