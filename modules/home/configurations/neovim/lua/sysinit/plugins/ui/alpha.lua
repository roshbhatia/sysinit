local M = {}

M.plugins = {
	{
		"goolord/alpha-nvim",
		commit = "de72250e054e5e691b9736ee30db72c65d560771",
		lazy = false,
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"nvim-telescope/telescope.nvim",
			"olimorris/persisted.nvim",
		},
		config = function()
			local alpha = require("alpha")
			local dashboard = require("alpha.themes.dashboard")

			dashboard.section.header.val = {
				"                                             ",
				"                     ....                    ",
				"               .#-+##.. .. .+                ",
				"            .####...         ...             ",
				"           ##.##.+.       ..    +.           ",
				"         .##.###..#       .  #-#...          ",
				"         -## ####-...   .##.     ##          ",
				"        .##. -######.  -.  .      #.         ",
				"        ###..-# .##+####.....   ..-.         ",
				"        ###  -#..#+###+##.####. #.#          ",
				"       .###  ##..######.......# -.           ",
				"       ####..##.#.#####.      #.  .          ",
				"       ####.+##.#-.##.#.     ###...          ",
				"      .###++-##..#.###...        .           ",
				"      .###...##.#######..  .##+.+.           ",
				"      .##....##..##.#####... .-.#.           ",
				"      +#....##- .....#####-.   .# .          ",
				"   ..#####+.##. .... .###########-..         ",
				"   ########.### ..-...#+##########-..        ",
				"  ########. ##.#+..#..+###########. #.       ",
				"   .........###++#### .###############       ",
				"            .+###-##+- .#############.#.     ",
				"                  .################ .....    ",
				"                    .####         .##.####   ",
				"                                             ",
			}

			dashboard.section.header.opts = {
				position = "center",
				hl = "DashboardHeader",
			}

			dashboard.section.buttons.val = function()
				local buttons = {}
				table.insert(buttons, dashboard.button("l", " Load last session", ":ene | SessionLoad<CR>"))
				table.insert(buttons, dashboard.button("i", " New file", ":ene | startinsert<CR>"))
				table.insert(buttons, dashboard.button("f", " Find file", ":ene | Telescope find_files<CR>"))
				table.insert(buttons, dashboard.button("g", " Grep files", ":ene | Telescope live_grep<CR>"))
				table.insert(
					buttons,
					dashboard.button("r", " Recently used files", ":ene | Telescope oldfiles only_cwd=true<CR>")
				)
				table.insert(buttons, dashboard.button("q", " Quit", ":qa<CR>"))
				return buttons
			end

			dashboard.section.buttons.opts = {
				hl = "DashboardCenter",
			}
			dashboard.opts.layout = {
				{
					type = "padding",
					val = 4,
				},
				dashboard.section.header,
				{
					type = "padding",
					val = 2,
				},
				dashboard.section.buttons,
				{
					type = "padding",
					val = 2,
				},
			}

			alpha.setup(dashboard.config)
		end,
	},
}

return M
