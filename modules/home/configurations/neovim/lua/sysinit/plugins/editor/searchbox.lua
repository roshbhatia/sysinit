local M = {}

M.plugins = {
	{
		"VonHeikemen/searchbox.nvim",
		dependencies = {
			"MunifTanjim/nui.nvim",
		},
		lazy = false,
		keys = function()
			return {
				{
					"<leader>ii",
					"<CMD>SearchBoxReplace<CR>",
					desc = "Search and replace within current file",
				},
				{
					"/",
					"<CMD>SearchBoxMatchAll<CR>",
				},
			}
		end,
	},
}

return M
