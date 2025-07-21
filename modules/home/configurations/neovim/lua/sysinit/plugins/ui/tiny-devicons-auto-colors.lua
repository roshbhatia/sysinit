local M = {}

M.plugins = {
	{
		"rachartier/tiny-devicons-auto-colors.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"catppuccin/nvim",
		},
		event = "VeryLazy",
		config = function()
			local theme_config = require("sysinit.theme_config")

			require("tiny-devicons-auto-colors").setup({
				colors = theme_config.palette,
			})
		end,
	},
}
return M
