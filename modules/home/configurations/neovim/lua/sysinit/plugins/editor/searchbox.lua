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
					"<leader>rf",
					"<CMD>SearchBoxReplace<CR>",
					desc = "Replace in current file",
				},
			}
		end,
	},
}

return M
