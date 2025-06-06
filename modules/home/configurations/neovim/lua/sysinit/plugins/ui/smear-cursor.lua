local M = {}

M.plugins = {
	{
		"sphamba/smear-cursor.nvim",
		event = "VeryLazy",
		opts = {
			smear_between_buffers = false,
			stiffness = 0.9,
			trailing_stiffness = 0.8,
			distance_stop_animating = 0.3,
			time_interval = 5,
			legacy_computing_symbols_support = true,
		},
	},
}

return M

