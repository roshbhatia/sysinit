local M = {}

local markdown_filetypes = {
	"markdown",
}

M.plugins = {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		commit = "a1b0988f5ab26698afb56b9c2f0525a4de1195c1",
		dependencies = { "3rd/image.nvim" },
		ft = markdown_filetypes,
		config = function()
			require("render-markdown").setup({
				anti_conceal = {
					enabled = false,
				},
				heading = {
					border_virtual = true,
					left_pad = 2,
				},
				code = {
					language_icon = false,
					language_name = false,
					language_pad = 2,
					left_padding = 2,
				},
				file_types = markdown_filetypes,
				render_modes = true,
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

