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
			min_horozontal_distance_smear = 2,
			smear_replace_mode = true,
			smear_insert_mode = false,
			transparent_bg_fallback_color = "#1e1e2e",
		},
	},
}

return M
