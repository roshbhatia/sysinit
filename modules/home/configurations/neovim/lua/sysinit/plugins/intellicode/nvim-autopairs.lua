local M = {}

M.plugins = {
	{
		"windwp/nvim-autopairs",
		deppendencies = {
			"nvim-treesitter",
		},
		event = "InsertEnter",
		config = true,
		opts = {
			check_ts = true,
		},
	},
}

return M

