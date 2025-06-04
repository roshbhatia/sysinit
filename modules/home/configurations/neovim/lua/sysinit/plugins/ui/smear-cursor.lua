local M = {}

M.plugins = {
	{
		"sphamba/smear-cursor.nvim",
		event = "VeryLazy",
		opts = {
			stiffness = 0.6,
			trailing_stiffness = 0.55,
		},
	},
}

return M

