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
					"<CMD>'<,'>Sort i<CR>",
					mode = "v",
					desc = "Sort alphabetically (case insensitive)",
				},
				{
					"<leader>sS",
					"<CMD>'<,'>Sort<CR>",
					mode = "v",
					desc = "Sort alphabetically (case sensitive)",
				},
				{
					"<leader>sr",
					"<CMD>'<,'>Sort! i<CR>",
					mode = "v",
					desc = "Sort reverse order (case insensitive)",
				},
				{
					"<leader>sR",
					"<CMD>'<,'>Sort!<CR>",
					mode = "v",
					desc = "Sort reverse order (case sensitive)",
				},
			}
		end,
	},
}

return M
