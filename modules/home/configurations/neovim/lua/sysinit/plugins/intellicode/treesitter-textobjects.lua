local M = {}

M.plugins = {
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		event = {
			"BufReadPost",
			"BufNewFile",
		},
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
	},
}

return M

