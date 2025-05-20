local M = {}

M.plugins = {
	{
		"sQVe/sort.nvim",
		event = "VisualEnter",
		opts = {},
		keys = function()
			return {
				{
					"v",
					"<Cmd>Sort<CR>",
					desc = "Sort: Sort selection alphabetically",
				},
			}
		end,
	},
}

return M

