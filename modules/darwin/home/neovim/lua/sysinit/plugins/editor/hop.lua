local M = {}

M.plugins = {
	{
		"smoka7/hop.nvim",
		event = "BufEnter",
		opts = {
			keys = "fjdkslaghrueiwoncmv",
			jump_on_sole_occurrence = false,
			case_sensitive = false,
		},
		keys = function()
			return {
				{
					"<S-CR>",
					"<cmd>HopWord<CR>",
					mode = "n",
					desc = "Hop: Quick jump to word",
				},
				{
					"<leader>j",
					"<cmd>HopWord<CR>",
					mode = "n",
					desc = "Hop: Quick jump to word",
				},
				{
					"<leader>jj",
					"<cmd>HopWord<CR>",
					mode = "n",
					desc = "Hop: Jump to any word",
				},
				{
					"<leader>jl",
					"<cmd>HopLine<CR>",
					mode = "n",
					desc = "Hop: Jump to any line",
				},
				{
					"<leader>js",
					"<cmd>HopChar1<CR>",
					mode = "n",
					desc = "Hop: Jump to character",
				},
				{
					"<leader>jp",
					"<cmd>HopPattern<CR>",
					mode = "n",
					desc = "Hop: Jump to pattern",
				},
			}
		end,
	},
}

return M
