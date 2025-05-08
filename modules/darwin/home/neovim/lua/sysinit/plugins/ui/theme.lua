local M = {}

M.plugins = {
	{ "folke/tokyonight.nvim" },
	{ "AlexvZyl/nordic.nvim" },
	{ "EdenEast/nightfox.nvim" },
	{ "shaunsingh/nord.nvim" },
	{ "marko-cerovac/material.nvim" },
	{
		"zaldih/themery.nvim",
		lazy = false,
		config = function()
			require("themery").setup({
				themes = { "tokyonight", "nordic", "nightfox", "nord", "material" },
				livePreview = true,
			})
		end,
	},
	{
		"nvchad/ui",
		config = function()
			require("nvchad")
		end,
	},
	{
		"nvchad/base46",
		build = function()
			require("base46").load_all_highlights()
		end,
	},
}

return M
