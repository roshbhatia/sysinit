local M = {}

M.plugins = {
  {
    "goolord/alpha-nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    lazy = false,
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")

      local fallback_ascii = {
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

      local ascii_lines = fallback_ascii
      local path = os.getenv("SYSINIT_NVIM_DASH_ASCII_PATH")
      if path then
        local file = io.open(path, "r")
        if file then
          ascii_lines = {}
          for line in file:lines() do
            table.insert(ascii_lines, line)
          end
          file:close()
        end
      end

      dashboard.section.header = {
        val = ascii_lines,
        opts = {
          position = "center",
          hl = "DashboardHeader",
        },
      }

      dashboard.section.buttons.val = function()
        local buttons = {}
        table.insert(
          buttons,
          dashboard.button("s", " Session: Load Last", ":ene | SessionLoad<CR>")
        )
        table.insert(
          buttons,
          dashboard.button("i", " File: Create New", ":ene | startinsert<CR>")
        )
        table.insert(
          buttons,
          dashboard.button("f", "󰍉 File: Search", ":ene | Telescope find_files hidden=true<CR>")
        )
        table.insert(
          buttons,
          dashboard.button("g", "󰍋 Strings: Search", ":ene | Telescope live_grep_args<CR>")
        )
        table.insert(buttons, dashboard.button("q", "󰩈 Vim: Exit", ":qa<CR>"))
        return buttons
      end

      dashboard.section.buttons.opts = {
        hl = "DashboardCenter",
      }

      dashboard.opts.layout = {
        { type = "padding", val = 4 },
        dashboard.section.header,
        { type = "padding", val = 2 },
        dashboard.section.buttons,
        { type = "padding", val = 2 },
      }

      alpha.setup(dashboard.config)
    end,
  },
}

return M

