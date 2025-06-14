local M = {}

M.plugins = {
	{
		"karb94/neoscroll.nvim",
		event = "BufReadPost",
		opts = {
			hide_cursor = true,
			stop_eof = true,
			respect_scrolloff = true,
			cursor_scrolls_alone = false,
			easing = "cubic",
			duration_multiplier = 1.2,
			performance_mode = false,
			mappings = {},
		},

		keys = function()
			local neoscroll = require("neoscroll")
			local map = function(lhs, fn)
				return { lhs, fn, mode = { "n", "v", "x" }, silent = true }
			end

			return {
				map("<C-u>", function()
					neoscroll.ctrl_u({ duration = 200, easing = "cubic" })
				end),
				map("<C-d>", function()
					neoscroll.ctrl_d({ duration = 200, easing = "cubic" })
				end),
				map("<C-b>", function()
					neoscroll.ctrl_b({ duration = 400, easing = "cubic" })
				end),
				map("<C-f>", function()
					neoscroll.ctrl_f({ duration = 400, easing = "cubic" })
				end),
				map("<C-y>", function()
					neoscroll.scroll(-1, { move_cursor = false, duration = 80, easing = "sine" })
				end),
				map("<C-e>", function()
					neoscroll.scroll(1, { move_cursor = false, duration = 80, easing = "sine" })
				end),
				map("zt", function()
					neoscroll.zt({ half_win_duration = 180, easing = "cubic" })
				end),
				map("zz", function()
					neoscroll.zz({ half_win_duration = 180, easing = "cubic" })
				end),
				map("zb", function()
					neoscroll.zb({ half_win_duration = 180, easing = "cubic" })
				end),

				map("<ScrollWheelUp>", function()
					neoscroll.scroll(-3, { move_cursor = false, duration = 100, easing = "quadratic" })
				end),
				map("<ScrollWheelDown>", function()
					neoscroll.scroll(3, { move_cursor = false, duration = 100, easing = "quadratic" })
				end),
			}
		end,
	},
}

return M
