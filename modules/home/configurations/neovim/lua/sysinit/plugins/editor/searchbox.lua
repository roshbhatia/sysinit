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
					"<leader>is",
					"<CMD>SearchBoxReplace<CR>",
					desc = "Local",
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
