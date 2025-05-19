local M = {}

M.plugins = {
	{
		"folke/trouble.nvim",
		event = "LSPAttach",
		opts = {
			win = "split",
		},
		keys = function()
			return {
				{
					"<leader>cx",
					"<cmd>Trouble diagnostics toggle focus=false win.position=right win.type=split pinned=true win.relative=win<cr>",
					desc = "Problems: Project Diagnostics",
				},
			}
		end,
	},
}

return M
