-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/nvim-tree/nvim-web-devicons/refs/heads/master/README.md"
local M = {}

M.plugins = {

	{
		"nvim-tree/nvim-web-devicons",
		opts = {},
	},
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

