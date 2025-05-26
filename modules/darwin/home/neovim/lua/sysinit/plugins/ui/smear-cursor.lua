local M = {}

M.plugins = {
	{
		"sphamba/smear-cursor.nvim",
		event = "VeryLazy",
		opts = {
			stiffness = 0.5,
			trailing_stiffness = 0.49,
		},
	},
}

return M

