local M = {}

M.plugins = {
	{
		"3rd/diagram.nvim",
		dependencies = {
			"3rd/image.nvim",
		},
		opts = {
			events = {
				render_buffer = {
					"InsertLeave",
					"BufWinEnter",
					"TextChanged",
				},
				clear_buffer = {
					"BufLeave",
				},
			},
			renderer_options = {
				mermaid = {
					theme = "dark",
					scale = 2,
				},
			},
		},
	},
}

return M
