local M = {}

M.plugins = {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		commit = "a1b0988f5ab26698afb56b9c2f0525a4de1195c1",
		dependencies = { "3rd/image.nvim" },
		config = function()
			require("render-markdown").setup({
				anti_conceal = {
					enabled = false,
				},
				code = {
					language_icon = false,
					language_name = false,
				},
				sign = {
					enabled = false,
				},
				completions = {
					lsp = {
						enabled = true,
					},
				},
			})
		end,
	},
}

return M

