local M = {}

M.plugins = {
	{
		"3rd/diagram.nvim",
		dependencies = {
			"3rd/image.nvim",
		},
		opts = {
			renderer_options = {
				mermaid = {
					background = "white",
					theme = "forest",
				},
			},
		},
	},
}

return M

