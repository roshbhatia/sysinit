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
					"<C-S-d>",
					":lua vim.cmd('normal! G')<CR>",
					mode = {
						"n",
					},
				},
				{
					"<C-S-u>",
					":lua vim.cmd('normal! gg')<CR>",
					mode = {
						"n",
					},
				},
			}
		end,
	},
}

return M

