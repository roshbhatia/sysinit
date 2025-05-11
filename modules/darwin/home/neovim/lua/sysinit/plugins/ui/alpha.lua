local M = {}

M.plugins = {
	{
		"goolord/alpha-nvim",
		commit = "de72250e054e5e691b9736ee30db72c65d560771",
		lazy = false,
		dependencies = { "nvim-tree/nvim-web-devicons", "folke/persistence.nvim", "nvim-telescope/telescope.nvim" },
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

			vim.api.nvim_create_autocmd("GUIEnter", {
				pattern = "*",
				callback = function()
					local persistence = require("persistence")
					local function should_load_session()
						local file = persistence.current()
						return vim.fn.filereadable(file) ~= 0
					end

					if not (next(vim.fn.argv()) ~= nil) then
						vim.opt.laststatus = 0
						vim.cmd("wincmd o")
						vim.cmd("Alpha")
					elseif vim.fn.argv() == 1 and vim.fn.argv()[1] == "." then
						if should_load_session() then
							persistence.load()
						else
							vim.cmd(":Telescope find_files")
						end
					end
				end,
			})
		end,
	},
}

return M
