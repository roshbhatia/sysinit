local M = {}

M.plugins = {
	{
		"3rd/diagram.nvim",
		dependencies = {
			"3rd/image.nvim",
		},
		config = function()
			require("diagram").setup({
				integrations = {
					require("diagram.integrations.markdown"),
				},
				renderer_options = {
					mermaid = {
						theme = "forest",
					},
					plantuml = {
						charset = "utf-8",
					},
					d2 = {
						theme_id = 1,
					},
					gnuplot = {
						theme = "dark",
						size = "800,600",
					},
				},
			})
		end,
	},
}

return M
