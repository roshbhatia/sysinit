local M = {}

M.plugins = {
	{
		"karb94/neoscroll.nvim",
		event = "BufReadPost",
		keys = function()
			return {
				{
					"<ScrollWheelUp>",
					"<C-y>",
					mode = { "n", "i", "v" },
				},
				{
					"<ScrollWheelDown>",
					"<C-e>",
					mode = { "n", "i", "v" },
				},
			}
		end,
		opts = {
			mappings = {
				"<C-y>",
				"<C-e>",
			},
			easing_function = "cubic",
		},
	},
}

return M

