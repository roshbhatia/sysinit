local M = {}

M.plugins = {
	{
		"echasnovski/mini.animate",
		version = "*",
		opts = {
			cursor = {
				enable = false,
			},
			scroll = {
				enable = false,
			},
			resize = {
				enable = true,
			},
			open = {
				enable = true,
			},
			close = {
				enable = true,
			},
		},
	},
}

return M

