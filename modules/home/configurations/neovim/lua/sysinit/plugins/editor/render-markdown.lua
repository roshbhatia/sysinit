local M = {}

M.plugins = {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		ft = {
			"Avante",
			"markdown",
			"codecompanion",
			"opencode_output",
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
					position = "left",
					language_icon = true,
				},
				pipe_table = {
					above = "─",
					below = "─",
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
					"codecompanion",
					"opencode_output",
				},
				sign = {
					enabled = false,
				},
			})
		end,
	},
}

return M

