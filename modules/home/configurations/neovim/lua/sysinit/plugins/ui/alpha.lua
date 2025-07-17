local M = {}

M.plugins = {
	{
		"goolord/alpha-nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		lazy = true,
		event = "VimEnter",
		config = function()
			local alpha = require("alpha")
			local dashboard = require("alpha.themes.dashboard")

			local function get_terminal_output(cmd)
				local handle = io.popen(cmd)
				if not handle then
					return {}
				end
				local result = handle:read("*a")
				handle:close()
				local lines = {}
				for line in result:gmatch("([^\n]*)\n?") do
					table.insert(lines, line)
				end
				return lines
			end

			local header_figlet = get_terminal_output("figlet -f catwalk sysinit")
			local header_chafa = get_terminal_output(
				"chafa $XDG_CONFIG_HOME/nvim/assets/frida.png --format symbols --symbols vhalf --size 60x17"
			)

			dashboard.section.header.val = {}
			for _, line in ipairs(header_figlet) do
				table.insert(dashboard.section.header.val, line)
			end
			for _, line in ipairs(header_chafa) do
				table.insert(dashboard.section.header.val, line)
			end

			dashboard.section.header.opts = {
				position = "center",
				hl = "DashboardHeader",
			}

			dashboard.section.buttons.val = function()
				local buttons = {}
				table.insert(buttons, dashboard.button("l", " Session: Load Last", ":ene | SessionLoad<CR>"))
				table.insert(buttons, dashboard.button("i", " File: Create New", ":ene | startinsert<CR>"))
				table.insert(buttons, dashboard.button("f", "󰍉 File: Search", ":ene | Telescope find_files<CR>"))
				table.insert(buttons, dashboard.button("g", "󰍋 Strings: Search", ":ene | Telescope live_grep<CR>"))
				table.insert(buttons, dashboard.button("q", "󰩈 Vim: Exit", ":qa<CR>"))
				return buttons
			end

			dashboard.section.buttons.opts = {
				hl = "DashboardCenter",
			}
			dashboard.opts.layout = {
				{
					type = "padding",
					val = 1,
				},
				dashboard.section.header,
				{
					type = "padding",
					val = 2,
				},
				dashboard.section.buttons,
				{
					type = "padding",
					val = 1,
				},
			}

			alpha.setup(dashboard.config)
		end,
	},
}

return M
