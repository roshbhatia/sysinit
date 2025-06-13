local M = {}

M.plugins = {
	{
		"karb94/neoscroll.nvim",
		event = "BufReadPost",
		opts = {
			mappings = {
				"<C-u>",
				"<C-d>",
			},
			hide_cursor = true,
			stop_eof = true,
			respect_scrolloff = false,
			cursor_scrolls_alone = true,
			easing_function = "cubic",
			performance_mode = false,
		},
		config = function(_, opts)
			require("neoscroll").setup(opts)

			local neoscroll = require("neoscroll")
			vim.keymap.set({ "n", "v", "x" }, "<C-u>", function()
				neoscroll.ctrl_u({ duration = 150 })
			end)
			vim.keymap.set({ "n", "v", "x" }, "<C-d>", function()
				neoscroll.ctrl_d({ duration = 150 })
			end)
		end,
		keys = function()
			return {
				{
					"<ScrollWheelUp>",
					function()
						require("neoscroll").scroll(-3, { move_cursor = false, duration = 100 })
					end,
					mode = { "n", "i", "v" },
				},
				{
					"<ScrollWheelDown>",
					function()
						require("neoscroll").scroll(3, { move_cursor = false, duration = 100 })
					end,
					mode = { "n", "i", "v" },
				},
			}
		end,
	},
}
return M
