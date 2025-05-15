local M = {}

M.plugins = {
	{
		"folke/trouble.nvim",
		event = "LSPAttach",
		opts = {
			win = split,
		},
		keys = function()
			return {
				{
					{
						"<leader>xa",
						"<cmd>Trouble diagnostics toggle focus=false win.position=right win.type=split pinned=true win.relative=win<cr>",
						desc = "Problems: Project Diagnostics"
					}
					{
						"<leader>xb",
						"<cmd>Trouble diagnostics toggle filter.buf=0 focus=false win.position=right win.type=split pinned=true win.relative=win<cr>",
						desc = "Problems: Buffer Diagnostics"
					},
					{
						"<leader>xq",
						"<cmd>Trouble qflist toggle focus=false win.position=right win.type=split pinned=true win.relative=win<cr>",
						desc = "Problems: Project Quickfix List"
					},
				},
			}
		end,
	},
}

return M

