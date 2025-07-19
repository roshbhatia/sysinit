local M = {}

M.plugins = {
	{
		"Bekaboo/dropbar.nvim",
		lazy = false,
		dependencies = {
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},
		config = function()
			require("dropbar").setup({
				icons = {
					ui = {
						bar = {
							separator = "  ",
							extends = "…",
						},
					},
				},
				menu = {
					preview = false,
					scrollbar = {
						enable = false,
					},
				},
				bar = {
					pick = {
						pivots = "fjdkslaghrueiwoncmv",
					},
				},
			})
		end,
		keys = function()
			local dropbar_api = require("dropbar.api")
			return {
				{
					"<leader>fw",
					dropbar_api.pick,
					mode = "n",
					desc = "Symbols in winbar",
				},
			}
		end,
	},
}

return M

