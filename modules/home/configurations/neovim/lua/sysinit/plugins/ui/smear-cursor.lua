local M = {}

M.plugins = {
	{
		"sphamba/smear-cursor.nvim",
		event = "VeryLazy",
		opts = {
			stiffness = 0.8,
			trailing_stiffness = 0.8,
			stiffness_insert_mode = 0.6,
			trailing_stiffness_insert_mode = 0.6,
			distance_stop_animating = 0.75,
			time_interval = 5,
			legacy_computing_symbols_support = true,
		},
	},
}

return M
