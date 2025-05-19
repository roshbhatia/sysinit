local M = {}

M.plugins = {
	{
		"jay-babu/mason-nvim-dap.nvim",
		commit = "4c2cdc69d69fe00c15ae8648f7e954d99e5de3ea",
		lazy = false,
		dependencies = {
			"mfussenegger/nvim-dap",
			"williamboman/mason.nvim",
		},
		opts = {
			handlers = {},
			ensure_installed = {
				"bash",
				"delve",
				"python",
			},
		},
	},
}

return M

