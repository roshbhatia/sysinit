local M = {}

M.plugins = {
	{
		"theHamsta/nvim-dap-virtual-text",
		event = "BufReadPost",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {},
	},
}

return M
