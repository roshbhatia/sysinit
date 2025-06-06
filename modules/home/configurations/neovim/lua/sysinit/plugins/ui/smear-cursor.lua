local M = {}

M.plugins = {
	{
		"sphamba/smear-cursor.nvim",
		event = "VeryLazy",
		opts = {
			stiffness = 0.5,
			trailing_stiffness = 0.49,
			time_interval = 5,
			legacy_computing_symbols_support = true,
		},
	},
}

return M
