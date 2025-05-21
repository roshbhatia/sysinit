local M = {}

M.plugins = {
	{
		"olimorris/persisted.nvim",
		event = "BufReadPre",
		opts = {},
	},
}

return M

