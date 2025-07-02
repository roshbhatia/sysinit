local M = {}

M.plugins = {
	{
		"folke/noice.nvim",
		priority = 1051,
		lazy = false,
		dependencies = {
			"MunifTanjim/nui.nvim",
		},
		config = function()
			require("noice").setup({
				cmdline = {
					enabled = false,
				},
				messages = {
					enabled = false,
				},
				popupmenu = {
					enabled = false,
				},
				notify = {
					enabled = false,
				},
				lsp = {
					progress = {
						enabled = false,
					},
				},
				presets = {
					lsp_doc_border = true,
				},
				hover = {
					enabled = false,
				},
			})
		end,
	},
}

return M
