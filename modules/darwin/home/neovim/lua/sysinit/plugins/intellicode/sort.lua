local M = {}

M.plugins = {
	{
		"sQVe/sort.nvim",
		event = "VeryLazy",
		opts = {},
		keys = function()
			return {
				{
					"v",
					"<leader>ss",
					"<Cmd>Sort<CR>",
					desc = "Sort: Sort selection alphabetically",
				},
			}
		end,
	},
}

return M

