local M = {}

M.plugins = {
	{
		"goolord/alpha-nvim",
		dependencies = { "nvim-tree/nvim-web-devicons", "folke/persistence.nvim" },
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

			vim.api.nvim_command("highlight DashboardHeader guifg=#ff0000")

			dashboard.section.buttons.val = function()
				local buttons = {}

				-- Check if a session exists for the current directory
				local persistence = require("persistence")
				local current_session = persistence.current()

				-- Only add the "Load last session" button if the session file exists
				if vim.fn.filereadable(current_session) == 1 then
					table.insert(
						buttons,
						dashboard.button("a", " Load last session", ':lua require("persistence").load() <CR>')
					)
				end

				-- Add the rest of the buttons
				table.insert(buttons, dashboard.button("i", " New file", ":ene <BAR> startinsert<CR>"))
				table.insert(buttons, dashboard.button("f", " Find file", ":Telescope find_files<CR>"))
				table.insert(buttons, dashboard.button("g", " Grep files", ":Telescope live_grep<CR>"))
				table.insert(buttons, dashboard.button("r", " Recently used files", ":Telescope oldfiles<CR>"))

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

			vim.api.nvim_create_autocmd("VimEnter", {
				pattern = "*",
				callback = function()
					if vim.fn.argc() > 0 and vim.fn.isdirectory(vim.fn.argv()[1]) == 1 then
						require("persistence").load()
					elseif vim.fn.argc() > 0 then
						return
					else
						vim.opt.laststatus = 0
						vim.cmd("Alpha")
					end
				end,
			})
		end,
	},
}

return M

