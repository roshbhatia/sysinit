local M = {}

M.plugins = {
	{
		"folke/snacks.nvim",
		commit = "bc0630e43be5699bb94dadc302c0d21615421d93",
		priority = 1050,
		lazy = false,
		config = function()
			require("snacks").setup({
				animate = {
					enabled = true,
					duration = 18,
					easing = "cubic",
					fps = 144,
				},
				bigfile = { enabled = true },
				bufdelete = { enabled = true },
				lazygit = {
					enabled = true,
					configure = false,
				},
				notifier = {
					enabled = true,
					timeout = 3000,
					level = vim.log.levels.ERROR,
					style = "minimal",
				},
				picker = {
					enabled = true,
				},
				quickfile = { enabled = true },
				rename = { enabled = true },
				scratch = { enabled = true },
				statuscolumn = { enabled = true },
				terminal = {
					enabled = true,
					border = "rounded",
				},
				words = { enabled = true },

				dashboard = { enabled = false },
				debug = { enabled = false },
				dim = { enabled = false },
				explorer = { enabled = false },
				git = { enabled = false },
				gitbrowse = { enabled = false },
				image = { enabled = false },
				indent = { enabled = false },
				input = { enabled = false },
				layout = { enabled = false },
				profiler = { enabled = false },
				scope = { enabled = false },
				scroll = { enabled = false },
				toggle = { enabled = false },
				win = { enabled = false },
				zen = { enabled = false },
			})
		end,
		keys = function()
			return {
				{
					"<leader>bs",
					function()
						Snacks.scratch()
					end,
					desc = "Buffer: Toggle scratchpad",
				},
				{
					"<leader>tt",
					function()
						Snacks.terminal.toggle("zsh")
					end,
					desc = "Terminal: Toggle terminal",
				},
				{
					"<leader>tl",
					function()
						Snacks.terminal.list()
					end,
					desc = "Terminal: List terminals",
				},
				{
					"<leader>tT",
					function()
						Snacks.terminal.open("zsh")
					end,
					desc = "Terminal: New terminal",
				},
				{
					"<leader>gg",
					function()
						Snacks.lazygit()
					end,
					desc = "Git: Open git ui",
				},
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
