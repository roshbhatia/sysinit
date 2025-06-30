local M = {}

M.plugins = {
	{
		"3rd/image.nvim",
		event = "VeryLazy",
		config = function()
			require("image").setup()
		end,
	},
}
return M
