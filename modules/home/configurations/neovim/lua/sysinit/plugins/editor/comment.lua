local M = {}

M.plugins = {
	{
		"echasnovski/mini.comment",
		event = "BufReadPost",
		version = "*",
	},
}

return M

