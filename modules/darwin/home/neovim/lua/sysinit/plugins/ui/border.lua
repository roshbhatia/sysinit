local M = {}

M.plugins = {
	{
		"mikesmithgh/borderline.nvim",
		lazy = true,
		event = "VeryLazy",
		config = function()
			require("borderline").setup({
				border = "single",
			})
		end,
	},
}

return M
