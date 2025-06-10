local M = {}

M.plugins = {
	{
		"theHamsta/nvim-dap-virtual-text",
		commit = "df66808cd78b5a97576bbaeee95ed5ca385a9750",
		event = "BufReadPost",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {},
	},
}

return M
