local M = {}

M.plugins = {
	{
		"sphamba/smear-cursor.nvim",
		event = "VeryLazy",
		opts = {
			stiffness = 0.8,
			trailing_stiffness = 0.65,
		},
	},
}

return M

