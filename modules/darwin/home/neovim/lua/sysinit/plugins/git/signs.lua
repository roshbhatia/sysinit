local M = {}

M.plugins = {
	{
		"lewis6991/gitsigns.nvim",
		event = { "VeryLazy" },
		config = function()
			require("gitsigns").setup({
				current_line_blame = false,
				current_line_blame_formatter = "",
			})
		end,
		keys = function()
			local gitsigns = require("gitsigns")
			return {
				{
					"n",
					"<leader>ghs",
					gitsigns.stage_hunk(),
					{ desc = "Git: Stage hunk" },
				},
				{
					"n",
					"<leader>ghr",
					gitsigns.reset_hunk(),
					{ desc = "Git: Reset hunk" },
				},
				{
					"n",
					"<leader>ghS",
					gitsigns.stage_buffer(),
					{ desc = "Git: Stage buffer" },
				},
				{
					"n",
					"<leader>ghu",
					gitsigns.undo_stage_hunk(),
					{ desc = "Git: Unstage hunk" },
				},
				{
					"n",
					"<leader>ghR",
					gitsigns.reset_buffer(),
					{ desc = "Git: Reset buffer" },
				},
				{
					"n",
					"<leader>ghp",
					gitsigns.preview_hunk_inline(),
					{ desc = "Git: Preview hunk" },
				},
				{
					"n",
					"<leader>ghd",
					gitsigns.diffthis(),
					{ desc = "Git: Diff with last commit" },
				},
				{
					"n",
					"<leader>ghd",
					gitsigns.diffthis("~"),
					{ desc = "Git: Diff with parent commit" },
				},
				{
					"n",
					"<leader>ghn",
					gitsigns.next_hunk(),
					{ desc = "Git: Next hunk" },
				},
				{
					"n",
					"<leader>ghp",
					gitsigns.prev_hunk(),
					{ desc = "Git: Previous hunk" },
				},
			}
		end,
	},
}

return M

