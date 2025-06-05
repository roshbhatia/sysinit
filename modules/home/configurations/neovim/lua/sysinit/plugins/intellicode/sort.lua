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
					"<leader>su",
					"<Cmd>Sort u<CR>",
					mode = "v",
					desc = "Sort uniquely",
				},
				{
					"<leader>si",
					"<Cmd>Sort i<CR>",
					mode = "v",
					desc = "Sort ignoring case",
				},
				{
					"<leader>sr",
					"<Cmd>Sort!<CR>",
					mode = "v",
					desc = "Sort reverse order",
				},
			}
		end,
	},
}

return M
