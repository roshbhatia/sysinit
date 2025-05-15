local M = {}

M.plugins = {
	{
		"smoka7/hop.nvim",
		-- Lazy loading based on the command(s) ensures highlight
		-- groups are not cleared.
		cmd = { "HopWord", "HopLine", "HopChar1", "HopPattern", "HopNodes", "HopAnywhere" },
		opts = {
			keys = "fjdkslaghrueiwoncmv",
			jump_on_sole_occurrence = false,
			case_sensitive = false,
		},
		keys = function()
			return {
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
				{
					"<leader>jt",
					"<cmd>HopNodes<CR>",
					mode = "n",
					desc = "Hop: Jump to node",
				},
				{
					"<leader>ja",
					"<cmd>HopAnywhere<CR>",
					mode = "n",
					desc = "Hop: Jump to anywhere",
				},
			}
		end,
	},
}

return M

