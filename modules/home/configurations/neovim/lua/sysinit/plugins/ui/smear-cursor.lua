local M = {}

M.plugins = {
	{
		"sphamba/smear-cursor.nvim",
		opts = {
			stiffness = 0.5,
			trailing_stiffness = 0.5,
			damping = 0.67,
			matrix_pixel_threshold = 0.5,
			legacy_computing_symbols_support = true,
		},
	},
}

return M
