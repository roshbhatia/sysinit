local M = {}

M.plugins = {
	{ "folke/tokyonight.nvim" },
	{ "AlexvZyl/nordic.nvim" },
	{ "EdenEast/nightfox.nvim" },
	{ "shaunsingh/nord.nvim" },
	{ "marko-cerovac/material.nvim" },
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
	{
		"nvchad/volt",
		lazy = false,
	},
}

return M
