local M = {}

M.plugins = {
	{
		"sQVe/sort.nvim",
		event = "VeryLazy",
		opts = {},
		keys = function()
			return {
				{
					"<leader>ss",
					"<Cmd>Sort il<CR>",
					mode = "v",
					desc = "Sort: Sort selection alphabetically",
				},
			}
		end,
	},
}

return M

