local M = {}

M.plugins = {
	{
		"folke/which-key.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		event = "VeryLazy",
		opts = {
			preset = "helix",
		},
	},
}

return M
