local M = {}

M.plugins = {
	{
		"karb94/neoscroll.nvim",
		event = "BufReadPost",
		opts = {
			easing = "cubic",
			duration_multiplier = 1.6,
			performance_mode = false,
			mappings = {
				"<C-y>",
				"<C-e>",
				"<C-d>",
				"<C-u>",
			},
		},
		keys = function()
			local neoscroll = require("neoscroll")
			return {
				{
					"<ScrollWheelUp>",
					"<C-y>",
					mode = {
						"n",
						"i",
						"v",
					},
				},
				{
					"<ScrollWheelDown>",
					"<C-e>",
					mode = {
						"n",
						"i",
						"v",
					},
				},
				{
					"<C-d>",
					function()
						neoscroll.scroll(vim.wo.scroll, true, 250)
					end,
					mode = {
						"n",
						"v",
					},
					desc = "Scroll down (smooth)",
				},
				{
					"<C-u>",
					function()
						neoscroll.scroll(-vim.wo.scroll, true, 250)
					end,
					mode = {
						"n",
						"v",
					},
					desc = "Scroll up (smooth)",
				},
			}
		end,
	},
}

return M
