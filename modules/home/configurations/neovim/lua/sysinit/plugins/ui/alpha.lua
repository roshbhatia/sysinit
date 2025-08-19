local M = {}

M.plugins = {
  {
    "goolord/alpha-nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    cmd = "Alpha",
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
        type = "text",
        val = ascii_lines,
        opts = {
          position = "center",
          hl = "DashboardHeader",
        },
      }

      dashboard.section.buttons = {
        type = "group",
        val = {
          dashboard.button("s", " Session: Load Last", ":ene | SessionLoad<CR>"),
          dashboard.button("i", " File: Create New", ":ene | startinsert<CR>"),
          dashboard.button("f", "󰍉 File: Search", ":ene | Telescope find_files hidden=true<CR>"),
          dashboard.button("g", "󰍋 Strings: Search", ":ene | Telescope live_grep_args<CR>"),
          dashboard.button("q", "󰩈 Vim: Exit", ":qa<CR>"),
        },
        opts = {
          hl = "DashboardCenter",
        },
      }

      dashboard.opts.layout = {
        { type = "padding", val = 4 },
        dashboard.section.header,
        { type = "padding", val = 2 },
        dashboard.section.buttons,
        { type = "padding", val = 2 },
      }

      alpha.setup(dashboard.opts)
    end,
  },
}

return M
