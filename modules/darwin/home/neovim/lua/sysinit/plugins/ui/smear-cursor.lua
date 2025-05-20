local M = {}

M.plugins = {
	{
		"sphamba/smear-cursor.nvim",
		event = "VeryLazy",
		opts = {
			stiffness = 0.9,
			trailing_stiffness = 0.75,
		},
	},
}

return M
