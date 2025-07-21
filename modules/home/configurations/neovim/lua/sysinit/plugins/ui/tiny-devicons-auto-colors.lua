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
			local theme_colors = {}

			if theme_config.colorscheme == "catppuccin" then
				theme_colors = require("catppuccin.palettes").get_palette(theme_config.variant)
			elseif theme_config.colorscheme == "rose-pine" then
				theme_colors = require("rose-pine.pallete").variants[theme_config.variant]
			elseif theme_config.colorscheme == "gruvbox" then
				theme_colors = require("gruvbox").get_colors()
			elseif theme_config.colorscheme == "solarized" then
				-- Use the palette from theme_config since solarized-osaka doesn't expose get_colors()
				theme_colors = theme_config.palette
			else
				-- Fallback to catppuccin macchiato
				theme_colors = require("catppuccin.palettes").get_palette("macchiato")
			end

			require("tiny-devicons-auto-colors").setup({
				colors = theme_colors,
			})
		end,
	},
}
return M

