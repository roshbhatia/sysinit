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
				code = {
					language_icon = true,
					language_name = false,
				},
				completions = {
					lsp = {
						enabled = true,
					},
				},
				file_types = {
					"Avante",
					"markdown",
					"octo",
				},
				sign = {
					enabled = false,
				},
			})
		end,
	},
}

return M

