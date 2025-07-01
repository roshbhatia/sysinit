local M = {}

M.plugins = {
	{
		"nvim-tree/nvim-web-devicons",
		opts = {
			override = {
				mermaid = {
					icon = "󰻴",
					color = "#b870b1",
					cterm_color = "65",
					name = "Mermaid",
				},
			},
		},
	},
}
return M

