local M = {}

M.plugins = {
	{
		"AckslD/muren.nvim",
		config = true,
		keys = function()
			return {
				{
					"<leader>fg",
					"<cmd>MurenToggle<cr>",
					desc = "Find: Global search",
				},
			}
		end,
	},
}

return M
