local M = {}

M.plugins = {
	{
		"3rd/image.nvim",
		build = false,
		opts = {
			processor = "magick_cli",
		},
	},
}

return M

