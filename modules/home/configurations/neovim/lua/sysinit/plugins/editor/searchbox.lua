local M = {}

M.plugins = {
	{
		"VonHeikemen/searchbox.nvim",
		dependencies = {
			"MunifTanjim/nui.nvim",
		},
		lazy = true,
		keys = function()
			return {
				{
					"<leader>ii",
					"<CMD>SearchBoxReplace<CR>",
					desc = "Search and replace within current file",
				},
			}
		end,
	},
}

return M

