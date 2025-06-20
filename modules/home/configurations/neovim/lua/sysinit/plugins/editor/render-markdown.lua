local M = {}

M.plugins = {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("render-markdown").setup({
				anti_conceal = {
					enabled = false,
				},
				code = {
					language_icon = false,
					language_name = false,
				},
				completions = {
					lsp = {
						enabled = true,
					},
				},
				file_types = {
					"markdown",
					"Avante",
				},
				sign = {
					enabled = false,
				},
				quote = {
					repeat_linebreak = true,
				},
			})
		end,
	},
}

return M
