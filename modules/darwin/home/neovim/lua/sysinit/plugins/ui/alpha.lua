local M = {}

M.plugins = {{
    "goolord/alpha-nvim",
    dependencies = {"nanozuki/tabby.nvim"},
    lazy = false,
    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")

        dashboard.section.header.val = {"                                             ",
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
                                        "                                             "}
        dashboard.section.header.opts = {
            position = "center",
            hl = "DashboardHeader"
        }

        dashboard.section.buttons.val = {dashboard.button("a", "  Load last session",
            ":lua require(\"persistence\").load() <CR>"),
                                         dashboard.button("i", "  New file", ":ene <BAR> startinsert<CR>"),
                                         dashboard.button("f", "  Find file", ":Telescope find_files<CR>"),
                                         dashboard.button("g", "  Grep files", ":Telescope live_grep<CR>"),
                                         dashboard.button("r", "  Recently used files", ":Telescope oldfiles<CR>")}

        dashboard.section.buttons.opts = {
            hl = "DashboardCenter"
        }
        dashboard.opts.layout = {{
            type = "padding",
            val = 4
        }, dashboard.section.header, {
            type = "padding",
            val = 2
        }, dashboard.section.buttons, {
            type = "padding",
            val = 2
        }}

        alpha.setup(dashboard.config)

        vim.api.nvim_create_autocmd("VimEnter", {
            pattern = "*",
            callback = function()
                vim.cmd()
                vim.cmd("Alpha")
            end
        })
    end
}}

return M
