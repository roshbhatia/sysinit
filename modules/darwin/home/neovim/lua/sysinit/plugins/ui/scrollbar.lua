local M = {}

M.plugins = {
	{
		"petertriho/nvim-scrollbar",
		event = "BufReadPost",
		opts = {},
	},
}

return M
