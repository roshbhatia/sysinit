local M = {}

M.plugins = {
	{
		"echasnovski/mini.animate",
		version = "*",
		config = function()
			require("mini.animate").setup({
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
			})
		end,
	},
}

return M
