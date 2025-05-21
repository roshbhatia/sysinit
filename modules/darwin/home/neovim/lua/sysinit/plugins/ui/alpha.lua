local M = {}

M.plugins = {
	{
		"goolord/alpha-nvim",
		commit = "de72250e054e5e691b9736ee30db72c65d560771",
		lazy = false,
		dependencies = { "nvim-tree/nvim-web-devicons", "nvim-telescope/telescope.nvim" },
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
				table.insert(buttons, dashboard.button("i", " New file", ":ene | startinsert<CR>"))
				table.insert(buttons, dashboard.button("f", " Find file", ":ene | Telescope find_files<CR>"))
				table.insert(buttons, dashboard.button("g", " Grep files", ":ene | Telescope live_grep<CR>"))
				table.insert(buttons, dashboard.button("r", " Recently used files", ":ene | Telescope oldfiles<CR>"))
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

			vim.api.nvim_create_autocmd("User", {
				pattern = "VeryLazy",
				callback = function()
					-- Get the exact startup command arguments
					local args = vim.v.argv
					local is_dir_open = false

					-- Check if we're opening a directory (specifically ".")
					if #args >= 2 then
						for i = 2, #args do
							if args[i] == "." then
								is_dir_open = true
								break
							end
						end
					end

					-- If opening directory and current buffer isn't a real file
					if is_dir_open and vim.fn.expand("%") == "" then
						-- Close any empty initial buffer or netrw
						vim.cmd("silent! enew")
						vim.cmd("silent! bd#")

						-- Force alpha to open
						vim.cmd("Alpha")
					end
				end,
				once = true,
			})
		end,
	},
}

return M
