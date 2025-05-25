local M = {}

M.plugins = {
	{
		"VonHeikemen/searchbox.nvim",
		dependencies = {
			"MunifTanjim/nui.nvim",
		},
		event = "VeryLazy",
		keys = function()
			return {
				{
					"<leader>ss",
					"<CMD>SearchBoxReplace<CR>",
					desc = "Search: Local",
				},
			}
		end,
	},
}

return M

