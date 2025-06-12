local M = {}

M.plugins = {
	{
		"sphamba/smear-cursor.nvim",
		event = "VeryLazy",
		opts = {
			distance_stop_animating = 0.3,
			legacy_computing_symbols_support = true,
			smear_between_buffers = false,
			stiffness = 0.9,
			trailing_stiffness = 0.8,
		},
	},
}

return M
