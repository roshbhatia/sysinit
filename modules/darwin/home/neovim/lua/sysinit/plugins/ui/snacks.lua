local M = {}

M.plugins = {
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			bigfile = { enabled = true },
			bufdelete = { enabled = true },
			image = { enabled = true },
			notifier = {
				enabled = true,
				timeout = 3000,
			},
			quickfile = { enabled = true },
			rename = { enabled = true },
			scope = { enabled = true },
			statuscolumn = { enabled = true },
			words = { enabled = true },

			animate = { enabled = false },
			dashboard = { enabled = false },
			debug = { enabled = false },
			dim = { enabled = false },
			explorer = { enabled = false },
			git = { enabled = false },
			gitbrowse = { enabled = false },
			indent = { enabled = false },
			input = { enabled = false },
			layout = { enabled = false },
			lazygit = { enabled = false },
			picker = { enabled = false },
			profiler = { enabled = false },
			scratch = { enabled = false },
			scroll = { enabled = false },
			terminal = { enabled = false },
			toggle = { enabled = false },
			win = { enabled = false },
			zen = { enabled = false },
		},
		keys = function()
			return {
				{
					"<leader>ns",
					function()
						Snacks.notifier.show_history()
					end,
					desc = "Notifications: Show",
				},
				{
					"<leader>nc",
					function()
						Snacks.notifier.hide()
					end,
					desc = "Notifications: Dismiss",
				},
			}
		end,
	},
}

return M
