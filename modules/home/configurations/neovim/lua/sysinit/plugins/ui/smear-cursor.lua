local M = {}

M.plugins = {
	{
		enabled = not vim.uv.fs_stat(vim.fn.expand("~/.nosmear")),
		"sphamba/smear-cursor.nvim",
		event = "VeryLazy",
		opts = {
			stiffness = 0.65,
			trailing_stiffness = 0.65,
			damping = 0.63,
			matrix_pixel_threshold = 0.5,
		},
	},
}

return M

