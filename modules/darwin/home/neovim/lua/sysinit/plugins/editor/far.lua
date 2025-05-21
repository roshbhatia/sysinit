local M = {}

M.plugins = {
	{
		"brooth/far.vim",
		commit = "796d60857ae4dcdae78c64bae69902503cca31f4",
		keys = function()
			return {
				{
					"<leader>fs",
					"<cmd>Farf<cr>",
					desc = "Find: Global search",
				},
				{
					"<leader>fr",
					"<cmd>Farr<cr>",
					desc = "Find: Global search and replace",
				},
			}
		end,
	},
}

return M
