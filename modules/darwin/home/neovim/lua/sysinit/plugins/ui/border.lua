local M = {}

M.plugins = {
	{
		"mikesmithgh/borderline.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("borderline").setup()
		end,
	},
}

return M
