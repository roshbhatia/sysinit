local M = {}

M.plugins = {
	{
		"sphamba/smear-cursor.nvim",
		event = "VeryLazy",
		opts = {
			stiffness = 0.55,
			trailing_stiffness = 0.5,
		},
	},
}

return M

