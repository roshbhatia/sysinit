local M = {}

M.plugins = {
	{
		"nvim-lua/plenary.nvim",
		priority = 9999, -- keep high priority for dependency order
		lazy = true,
	},
}

return M
