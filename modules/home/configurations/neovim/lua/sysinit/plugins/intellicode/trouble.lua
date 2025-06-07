local M = {}

M.plugins = {
	{
		"folke/trouble.nvim",
		event = "LSPAttach",
		opts = {
			auto_preview = false,
			open_no_results = true,
			use_diagnostic_signs = true,
			preview = {
				type = "float",
			},
		},
		keys = function()
			return {
				{
					"<leader>cx",
					"<CMD>Trouble diagnostics toggle focus=false win.position=right win.type=split preview.type=float pinned=true win.relative=win<CR>",
					desc = "Project diagnostics",
				},
				{
					"<leader>cX",
					"<cmd>Trouble qflist toggle<cr>",
					desc = "Project diagnostics quickfix List",
				},
			}
		end,
	},
}

return M
