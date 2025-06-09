local M = {}

M.plugins = {
	{
		"rachartier/tiny-devicons-auto-colors.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		event = "VeryLazy",
		config = function()
			require("tiny-devicons-auto-colors").setup({
				autoreload = true,
			})
		end,
	},
}
return M
