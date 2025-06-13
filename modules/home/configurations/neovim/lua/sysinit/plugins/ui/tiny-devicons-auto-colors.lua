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
			local theme_colors = require("catppuccin.palettes").get_palette("frappe")

			require("tiny-devicons-auto-colors").setup({
				colors = theme_colors,
			})
		end,
	},
}
return M
