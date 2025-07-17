local M = {}

M.plugins = {
	{
		"folke/snacks.nvim",
		priority = 1050,
		lazy = false,
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("snacks").setup({
				animate = {
					enabled = true,
					duration = 18,
					fps = 144,
				},
				bigfile = {
					enabled = true,
				},
				bufdelete = {
					enabled = true,
				},
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
				rename = {
					enabled = true,
				},
				scratch = {
					enabled = true,
				},
				statuscolumn = {
					enabled = false,
				},
				words = {
					enabled = true,
				},
				dashboard = {
					enabled = true,
					sections = {
						{
							pane = 1,
							{
								section = "terminal",
								cmd = "figlet -f catwalk sysinit | lolcat",
								padding = 1,
							},
							{
								section = "terminal",
								cmd = "chafa $XDG_CONFIG_HOME/nvim/assets/frida.png --format symbols --symbols vhalf --size 60x17; sleep .1",
								height = 17,
								padding = 1,
							},
						},
						{
							pane = 2,
							{
								section = "keys",
								gap = 1,
								padding = 1,
							},
						},
					},
					buttons = {
						{
							text = {
								{ " ", hl = "SnacksDashboardIcon" },
								{ "Session: Load Last", hl = "SnacksDashboardDesc", width = 50 },
								{ "[l]", hl = "SnacksDashboardKey" },
							},
							action = ":ene | SessionLoad",
							key = "l",
						},
						{
							text = {
								{ " ", hl = "SnacksDashboardIcon" },
								{ "File: Create New", hl = "SnacksDashboardDesc", width = 50 },
								{ "[i]", hl = "SnacksDashboardKey" },
							},
							action = ":ene | startinsert",
							key = "i",
						},
						{
							text = {
								{ "󰍉 ", hl = "SnacksDashboardIcon" },
								{ "File: Search", hl = "SnacksDashboardDesc", width = 50 },
								{ "[f]", hl = "SnacksDashboardKey" },
							},
							action = ":ene | Telescope find_files",
							key = "f",
						},
						{
							text = {
								{ "󰍋 ", hl = "SnacksDashboardIcon" },
								{ "Strings: Search", hl = "SnacksDashboardDesc", width = 50 },
								{ "[g]", hl = "SnacksDashboardKey" },
							},
							action = ":ene | Telescope live_grep",
							key = "g",
						},
						{
							text = {
								{ "󰩈 ", hl = "SnacksDashboardIcon" },
								{ "Vim: Exit", hl = "SnacksDashboardDesc", width = 50 },
								{ "[q]", hl = "SnacksDashboardKey" },
							},
							action = ":qa!",
							key = "q",
						},
					},
				},
				debug = {
					enabled = false,
				},
				dim = {
					enabled = false,
				},
				explorer = {
					enabled = false,
				},
				git = {
					enabled = false,
				},
				gitbrowse = {
					enabled = false,
				},
				image = {
					enabled = false,
				},
				indent = {
					enabled = false,
				},
				layout = {
					enabled = false,
				},
				profiler = {
					enabled = true,
				},
				quickfile = {
					enabled = true,
				},
				terminal = {
					enabled = false,
				},
				scope = {
					enabled = false,
				},
				scroll = {
					enabled = false,
				},
				toggle = {
					enabled = false,
				},
				win = {
					enabled = false,
				},
				zen = {
					enabled = false,
				},
			})

			vim.notify = Snacks.notifier
			vim.ui.input = Snacks.input
		end,
		keys = function()
			local default_keys = {
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
					function()
						Snacks.notifier.show_history()
					end,
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

			if vim.env.SYSINIT_DEBUG ~= "1" then
				return default_keys
			end

			local debug_keys = {
				{
					"<localleader>px",
					function()
						Snacks.profiler.stop()
					end,
					desc = "Stop Profiler",
				},
				{
					"<localleader>pf",
					function()
						Snacks.profiler.pick()
					end,
					desc = "Profiler Picker",
				},
				{
					"<localleader>pp",
					function()
						Snacks.toggle.profiler()
					end,
					desc = "Toggle Profiler",
				},
				{
					"<localleader>ph",
					function()
						Snacks.toggle.profiler_highlights()
					end,
					desc = "Toggle Profiler Highlights",
				},
				{
					"<localleader>ps",
					function()
						Snacks.profiler.scratch()
					end,
					desc = "Profiler Scratch Buffer",
				},
			}

			for _, key in ipairs(debug_keys) do
				table.insert(default_keys, key)
			end

			return default_keys
		end,
	},
}

return M
