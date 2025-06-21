local M = {}

M.plugins = {
	{
		"folke/snacks.nvim",
		priority = 1050,
		lazy = false,
		config = function()
			require("snacks").setup({
				animate = {
					enabled = true,
					duration = 18,
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
					margin = {
						top = 1,
						right = 1,
						bottom = 0,
					},
					style = "minimal",
					timeout = 1500,
				},
				picker = {
					enabled = true,
					ui_select = false,
					formatters = {
						d = {
							show_always = false,
							unselected = false,
						},
					},
					icons = {
						ui = {
							selected = " ",
							unselected = " ",
						},
					},
				},
				rename = { enabled = true },
				scratch = { enabled = true },
				statuscolumn = { enabled = true },
				words = { enabled = true },

				dashboard = { enabled = false },
				debug = { enabled = false },
				dim = { enabled = false },
				explorer = { enabled = false },
				git = { enabled = false },
				gitbrowse = { enabled = false },
				image = { enabled = false },
				indent = { enabled = false },
				layout = { enabled = false },
				profiler = { enabled = false },
				quickfile = { enabled = false }, -- Causes issues with syntax highlighting?
				terminal = { enabled = false },
				scope = { enabled = false },
				scroll = { enabled = false },
				toggle = { enabled = false },
				win = { enabled = false },
				zen = { enabled = false },
			})

			vim.notify = Snacks.notifier
		end,
		keys = function()
			return {
				{
					"<leader>bs",
					function()
						Snacks.scratch()
					end,
					desc = "Toggle scratchpad",
				},
				{
					"<leader>gg",
					function()
						Snacks.lazygit()
					end,
					desc = "Open UI",
				},
				{
					"<leader>ns",
					"<CMD>NoiceSnacks<CR>",
					desc = "Show",
				},
				{
					"<leader>nc",
					function()
						Snacks.notifier.hide()
					end,
					desc = "Dismiss",
				},
			}
		end,
	},
}

return M
