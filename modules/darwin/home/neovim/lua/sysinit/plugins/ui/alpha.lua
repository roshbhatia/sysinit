local M = {}

M.plugins = {{
    "goolord/alpha-nvim",
    event = "VimEnter",
    enabled = true,
    opts = function()
        local dashboard = require("alpha.themes.dashboard")
        dashboard.section.header.val = {"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣄⠀⠀⠀⠀⠀⠀⠀",
                                        "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠃⠀⠀⠀⠀⠀⠀⠀",
                                        "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⠀⠀⠀⠀⠀⠀⠀⠀",
                                        "⠀⠀⠀⠀⠀⠀⢀⠀⠀⣦⣧⡀⠀⠀⠀⠀⠀⠀⠀",
                                        "⠀⠀⠀⠀⠀⠀⠆⠀⡆⢸⠏⠁⠀⠀⠀⠀⠀⠀⠀",
                                        "⠀⠀⠀⠀⠀⢸⠀⠀⠈⣼⠀⡀⠀⠀⠀⠀⠀⠀⠀",
                                        "⠀⠀⠀⠀⠀⠈⣧⡀⡆⠇⠀⢳⠀⠀⠀⠀⠀⠀⠀",
                                        "⠀⠀⠀⠀⢠⠀⢸⡷⣿⠄⡆⡜⠀⠀⠀⠀⠀⠀⠀",
                                        "⠀⠀⠀⠀⡈⠁⢞⢱⣿⡀⢿⠀⠀⠀⠀⠀⠀⠀⠀",
                                        "⠀⠀⠀⠀⠇⢳⢪⣿⣿⣿⡎⢈⠆⠀⠀⠀⠀⠀⠀",
                                        "⠀⠀⠀⠀⠀⠯⢸⣿⣿⣿⣯⢆⢀⣀⠀⠀⠀⠀⠀",
                                        "⠀⠀⠀⠴⢒⡐⣛⠿⠿⡟⡨⣊⡤⢖⣲⢄⡀⠀⠀",
                                        "⠀⣀⡤⢚⡽⢊⠞⢰⠁⡇⠈⠪⣙⠳⢮⣝⡒⠤⡀",
                                        "⠊⠁⠒⢁⡴⠋⠀⡏⠀⣇⠀⠀⠙⠷⠀⠉⠛⠀⠀",
                                        "⠀⠀⠘⠉⠀⠀⠀⠁⠀⠙⠀⠀⠀⠀⠀⠀⠀⠀⠀"}
        dashboard.section.header.opts = {
            position = "center",
            hl = "DashboardHeader"
        }

        dashboard.section.buttons.val = {dashboard.button("f", "  Find file", ":Telescope find_files<CR>"),
                                         dashboard.button("e", "  New file", ":ene <BAR> startinsert<CR>"),
                                         dashboard.button("p", "  Find project", ":Telescope projects<CR>"),
                                         dashboard.button("r", "  Recently used files", ":Telescope oldfiles<CR>"),
                                         dashboard.button("t", "  Find text", ":Telescope live_grep<CR>"),
                                         dashboard.button("c", "  Configuration", ":e $MYVIMRC<CR>"),
                                         dashboard.button("q", "  Quit Neovim", ":qa<CR>")}

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
        return dashboard.opts
    end
}}

return M
