local M = {}

M.plugins = {
	{
		"folke/trouble.nvim",
		cmd = { "Trouble" },
		opts = {},
		keys = function()
			return {
				{
					"<leader>xx",
					"<cmd>Trouble diagnostics toggle<cr>",
					desc = "Problems: Diagnostics",
				},
				{
					"<leader>xX",
					"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
					desc = "Problems: Buffer Diagnostics",
				},
				{
					"<leader>cs",
					"<cmd>Trouble symbols toggle focus=false<cr>",
					desc = "Problems: Symbols",
				},
				{
					"<leader>cl",
					"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
					desc = "Problems: LSP Definitions / references / ...",
				},
				{
					"<leader>xL",
					"<cmd>Trouble loclist toggle<cr>",
					desc = "Problems: Location List",
				},
				{
					"<leader>xQ",
					"<cmd>Trouble qflist toggle<cr>",
					desc = "Problems: Quickfix List",
				},
			}
		end,
	},
}

return M
