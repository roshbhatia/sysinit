local M = {}

M.plugins = {
	{
		"folke/trouble.nvim",
		event = "LSPAttach",
		opts = {
			open_no_results = true,
			win = "split",
		},
		keys = function()
			return {
				{
					"<leader>cx",
					"<CMD>Trouble diagnostics toggle focus=false win.position=right win.type=split pinned=true win.relative=win<CR>",
					desc = "Project Diagnostics",
				},
			}
		end,
	},
}

return M
