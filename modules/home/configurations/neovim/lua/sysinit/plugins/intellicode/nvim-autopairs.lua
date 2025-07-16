local M = {}

M.plugins = {
	{
		"windwp/nvim-autopairs",
		deppendencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		event = "BufReadPre",
		config = true,
		opts = {
			check_ts = true,
		},
	},
}

return M

