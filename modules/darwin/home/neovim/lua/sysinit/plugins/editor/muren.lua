local M = {}

M.plugins = {
	{
		"brooth/far.vim",
		keys = function()
			return {
				{
					"<leader>fs",
					"<cmd>Farr<cr>",
					desc = "Find: Global search",
				},
				{
					"<leader>fr",
					"<cmd>Farf<cr>",
					desc = "Find: Global search and replace",
				},
			}
		end,
	},
}

return M

