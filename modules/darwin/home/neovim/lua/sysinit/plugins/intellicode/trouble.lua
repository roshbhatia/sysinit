local M = {}

M.plugins = {
	{
		"folke/trouble.nvim",
		cmd = { "Trouble" },
		opts = {
			win = {
				preview = {
					type = "split",
					scratch = true,
				},
			},
		},
		keys = function()
			return {
				{
					"<leader>cx",
					"<cmd>Trouble diagnostics toggle<cr>",
					desc = "Problems: Diagnostics",
				},
				{
					"<leader>cxX",
					"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
					desc = "Problems: Buffer Diagnostics",
				},
				{
					"<leader>cxs",
					"<cmd>Trouble symbols toggle focus=false<cr>",
					desc = "Problems: Symbols",
				},
				{
					"<leader>cxl",
					"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
					desc = "Problems: LSP Definitions / references / ...",
				},
				{
					"<leader>cxL",
					"<cmd>Trouble loclist toggle<cr>",
					desc = "Problems: Location List",
				},
				{
					"<leader>cxQ",
					"<cmd>Trouble qflist toggle<cr>",
					desc = "Problems: Quickfix List",
				},
			}
		end,
	},
}

return M

