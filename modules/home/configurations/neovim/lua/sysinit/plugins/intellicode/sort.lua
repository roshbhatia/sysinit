local M = {}

M.plugins = {
	{
		"sQVe/sort.nvim",
		config = function()
			require("sort").setup({
				delimiters = {
					",",
					"|",
					";",
					":",
					"s",
					"t",
					"\n",
				},
			})
		end,
		keys = function()
			return {
				{
					"<leader>ss",
					"<CMD>sort<CR>",
					mode = "v",
					desc = "Sort alphabetically",
				},
				{
					"<leader>su",
					"<CMD>Sort u<CR>",
					mode = "v",
					desc = "Sort uniquely",
				},
				{
					"<leader>si",
					"<CMD>Sort i<CR>",
					mode = "v",
					desc = "Sort ignoring case",
				},
				{
					"<leader>sr",
					"<CMD>Sort!<CR>",
					mode = "v",
					desc = "Sort reverse order",
				},
			}
		end,
	},
}

return M
