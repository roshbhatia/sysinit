local M = {}

M.plugins = {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		commit = "6f5a4c36d9383b2a916facaa63dcd573afa11ee8",
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

