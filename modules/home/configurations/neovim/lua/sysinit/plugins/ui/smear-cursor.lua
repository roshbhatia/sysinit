local M = {}

M.plugins = {
	{
		"sphamba/smear-cursor.nvim",
		event = "VeryLazy",
		opts = {
			stiffness = 0.8,
			trailing_stiffness = 0.8,
			time_interval = 5,
			legacy_computing_symbols_support = true,
		},
	},
}

return M

