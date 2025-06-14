local M = {}

M.plugins = {
	{
		"karb94/neoscroll.nvim",
		event = "BufReadPost",
		opts = {
			hide_cursor = false,
			stop_eof = false,
			respect_scrolloff = true,
			cursor_scrolls_alone = false,
			easing = "cubic",
			duration_multiplier = 1.6,
			performance_mode = false,
			mappings = {},
		},

		keys = function()
			local neoscroll = require("neoscroll")
			return {
				{
					"<C-u>",
					function()
						neoscroll.ctrl_u({ duration = 200, easing = "cubic" })
					end,
					mode = { "n", "v", "x" },
					silent = true,
				},
				{
					"<C-d>",
					function()
						neoscroll.ctrl_d({ duration = 200, easing = "cubic" })
					end,
					mode = { "n", "v", "x" },
					silent = true,
				},
				{
					"<C-b>",
					function()
						neoscroll.ctrl_b({ duration = 400, easing = "cubic" })
					end,
					mode = { "n", "v", "x" },
					silent = true,
				},
				{
					"<C-f>",
					function()
						neoscroll.ctrl_f({ duration = 400, easing = "cubic" })
					end,
					mode = { "n", "v", "x" },
					silent = true,
				},
				{
					"<C-y>",
					function()
						neoscroll.scroll(-1, { duration = 80, easing = "sine" })
					end,
					mode = { "n", "v", "x" },
					silent = true,
				},
				{
					"<C-e>",
					function()
						neoscroll.scroll(1, { duration = 80, easing = "sine" })
					end,
					mode = { "n", "v", "x" },
					silent = true,
				},
				{
					"zt",
					function()
						neoscroll.zt({ half_win_duration = 180, easing = "cubic" })
					end,
					mode = { "n", "v", "x" },
					silent = true,
				},
				{
					"zz",
					function()
						neoscroll.zz({ half_win_duration = 180, easing = "cubic" })
					end,
					mode = { "n", "v", "x" },
					silent = true,
				},
				{
					"zb",
					function()
						neoscroll.zb({ half_win_duration = 180, easing = "cubic" })
					end,
					mode = { "n", "v", "x" },
					silent = true,
				},
				{
					"<ScrollWheelUp>",
					function()
						neoscroll.scroll(-3, { duration = 50, easing = "quadratic" })
					end,
					mode = { "n", "v", "x" },
					silent = true,
				},
				{
					"<ScrollWheelDown>",
					function()
						neoscroll.scroll(3, { duration = 50, easing = "quadratic" })
					end,
					mode = { "n", "v", "x" },
					silent = true,
				},
			}
		end,
	},
}

return M

