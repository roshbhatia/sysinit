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
							section = "terminal",
							cmd = "chafa $XDG_CONFIG_HOME/nvim/assets/wall.png --format symbols --symbols vhalf --size 60x17; sleep .1",
							height = 17,
							padding = 1,
						},
						{
							section = "header",
							cmd = "figlet -f catwalk sysinit | lolcat",
							padding = 1,
						},
						{
							pane = 2,
							{ section = "keys", gap = 1, padding = 1 },
							{ section = "startup" },
						},
					},
					buttons = {
						{ key = "l", label = "  Session: Load Last", action = ":ene | SessionLoad<CR>" },
						{ key = "i", label = "  File: Create New", action = ":ene | startinsert<CR>" },
						{ key = "f", label = "󰍉 File: Search", action = ":ene | Telescope find_files<CR>" },
						{ key = "g", label = "󰍋 Strings: Search", action = ":ene | Telescope live_grep<CR>" },
						{ key = "q", label = "󰩈 Vim: Exit", action = ":qa<CR>" },
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
