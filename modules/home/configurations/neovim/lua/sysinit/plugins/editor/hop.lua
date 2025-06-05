local M = {}

M.plugins = {
	{
		"smoka7/hop.nvim",
		commit = "9c6a1dd9afb53a112b128877ccd583a1faa0b8b6",
		cmd = { "HopWord", "HopLine", "HopChar1", "HopPattern", "HopNodes", "HopAnywhere" },
		opts = {
			keys = "fjdkslaghrueiwoncmv",
			jump_on_sole_occurrence = false,
			case_sensitive = false,
		},
		keys = function()
			return {
				{
					"<S-CR>",
					"<CMD>HopWord<CR>",
					mode = "n",
					desc = "Jump to any word",
				},
				{
					"<leader>jj",
					"<CMD>HopWord<CR>",
					mode = "n",
					desc = "Jump to any word",
				},
				{
					"<leader>jl",
					"<CMD>HopLine<CR>",
					mode = "n",
					desc = "Jump to any line",
				},
				{
					"<leader>js",
					"<CMD>HopChar1<CR>",
					mode = "n",
					desc = "Jump to character",
				},
				{
					"<leader>jp",
					"<CMD>HopPattern<CR>",
					mode = "n",
					desc = "Jump to pattern",
				},
				{
					"<leader>jt",
					"<CMD>HopNodes<CR>",
					mode = "n",
					desc = "Jump to node",
				},
				{
					"<leader>ja",
					"<CMD>HopAnywhere<CR>",
					mode = "n",
					desc = "Jump to anywhere",
				},
			}
		end,
	},
}

return M
