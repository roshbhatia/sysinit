local M = {}

M.plugins = {
	{
		"nvchad/base46",
		build = function()
			require("base46").load_all_highlights()
		end,
	},
	{
		"MunifTanjim/nui.nvim",
		lazy = false,
	},
}

return M
