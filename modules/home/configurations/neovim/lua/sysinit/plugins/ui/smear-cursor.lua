local M = {}

M.plugins = {
	{
		"sphamba/smear-cursor.nvim",
		event = "VeryLazy",
		opts = {
			stiffness = 0.5,
			trailing_stiffness = 0.49,
			time_interval = 5,
			transparent_bg_fallback_color = vim.api.nvim_get_hl_by_name("Normal", true).background,
		},
	},
}

return M

