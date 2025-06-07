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
					"<leader>is",
					"<CMD>SearchBoxReplace<CR>",
					desc = "Search and replace within current file",
				},
				{
					"/",
					"<CMD>SearchBoxIncSearch<CR>",
				},
			}
		end,
	},
}

return M

