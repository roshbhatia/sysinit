local M = {}

M.plugins = {
	{
		"echasnovski/mini.animate",
		version = "*",
		config = function()
			require("mini.animate").setup()
		end,
	},
}

return M
