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
				headings = {
					border_virtual = true,
				},
				code = {
					border = "thin",
					disable_background = true,
					language_icon = true,
					language_name = false,
				},
				pipe_table = {
					border = {
						"╭",
						"┬",
						"╮",
						"├",
						"┼",
						"┤",
						"╰",
						"┴",
						"╯",
						"│",
						"─",
					},
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
