local M = {}

M.plugins = {
	{
		"folke/noice.nvim",
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
				lsp = {
					progress = {
						enabled = false,
					},
					override = {
						["vim.lsp.util.convert_input_to_markdown_lines"] = true,
						["vim.lsp.util.stylize_markdown"] = true,
					},
				},
				presets = {
					lsp_doc_border = true,
				},
			})
		end,
	},
}

return M
