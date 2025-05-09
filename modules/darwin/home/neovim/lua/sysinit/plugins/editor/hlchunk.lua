local M = {}

M.plugins = {
	{
		"shellRaining/hlchunk.nvim",
		event = { "VeryLazy" },
		config = function()
			require("hlchunk").setup({
				line_num = {
					enablechunk = true,
				},
			})
		end,
	},
}

return M
