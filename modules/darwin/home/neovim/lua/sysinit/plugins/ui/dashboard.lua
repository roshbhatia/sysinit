local M = {}

M.plugins = {{
    "goolord/alpha-nvim",
    lazy = false,
    priority = 100,
    dependencies = {"nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim"},
    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")
        local win_width = vim.o.columns

        -- Set header
        dashboard.section.header.val =
            {"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣄⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
             "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⡉⣇⡌⡟⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
             "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣷⡳⣯⠟⠛⠳⣿⢷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
             "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣄⠀⠀⠀⠀⣠⡟⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
             "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣦⣠⣤⠞⠍⠀⣿⣦⣢⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
             "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣷⣦⣔⠀⠠⣻⡿⣻⡿⠗⠊⠉⠒⢦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
             "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⡗⢿⣻⣴⣾⣫⠾⢻⡇⡠⣶⣲⠫⡾⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀",
             "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡝⣧⠀⡯⣿⠋⣠⠼⣿⣿⣍⢧⠙⣤⣽⣾⣟⡄⠀⠀⠀⠀⠀⠀⠀⠀",
             "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⠉⢾⣷⣿⣯⣰⣛⣽⡿⣿⣿⠷⣿⢿⣟⣜⣜⣜⡄⠀⠀⠀⠀⠀⠀⠀",
             "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣷⣶⡏⡏⢳⡺⠛⣻⣿⣿⣿⣇⢹⠎⢞⣞⣜⡼⡿⠆⠀⠀⠀⠀⠀⠀",
             "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣤⢿⣿⡇⣇⠜⢀⡞⢹⠀⣿⣿⣿⡞⡎⣈⣮⠾⣿⡆⠀⠀⠀⠀⠀⠀⠀",
             "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⡇⠀⣿⡷⠃⡰⠋⡇⢸⡄⠘⢿⣿⣿⡋⠉⠀⠀⣹⣿⡀⠀⣀⣀⠀⠀⠀",
             "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⢻⣿⣿⣿⠀⡆⢳⠈⡇⣀⣾⣿⣿⣿⡔⣚⠉⠀⢹⣧⡴⢯⣭⡇⠀⠀",
             "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⡿⣸⣿⡿⣿⣿⣤⣈⣤⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⡠⠋⢸⣿⡀⠀",
             "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⢱⣿⣿⣿⣿⣷⣄⣉⣙⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠁⠀⠀⢸⣿⡇⠀",
             "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⡘⢿⣼⣿⢿⣿⢾⣛⡟⠛⣿⠿⠟⠛⠛⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⢹⣿⣿⠀",
             "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣟⠹⢄⣴⣿⣽⡟⡿⣶⣿⣋⣈⣧⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣾⣿⡟⡄",
             "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠿⣵⣶⣿⣻⡿⢤⢁⣾⡏⡟⠇⣏⣉⣡⣤⡿⠃⡜⠁⠀⠀⠀⠀⠀⠀⠀⣿⣷⣿⡇",
             "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣿⣫⣿⣿⣯⡮⣟⣺⣿⢹⣿⣿⠜⢦⣽⡟⠀⡜⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⡇",
             ""}
        local auto_session = require("auto-session")

        dashboard.section.header.opts.hl = "ProfileRed"

        -- Set menu with conditional session button
        dashboard.section.buttons.val = {require('auto-session.lib').current_session_name(true) and
            dashboard.button("a", "  Load Last Session", ":SessionRestore<CR>") or nil,
                                         dashboard.button("i", "  Init Buffer", ":enew<CR>"),
                                         dashboard.button("f", "  Find Files", ":Telescope find_files<CR>"),
                                         dashboard.button("r", "  Recent Files", ":Telescope oldfiles<CR>"),
                                         dashboard.button("g", "  Live Grep", ":Telescope live_grep<CR>"),
                                         dashboard.button("q", "  Quit", ":qa<CR>")}

        -- Filter out nil values in case session button isn't shown
        dashboard.section.buttons.val = vim.tbl_filter(function(item)
            return item ~= nil
        end, dashboard.section.buttons.val)
        -- Footer with git contributions (simplified)
        local function get_git_contributions()
            -- This is a placeholder. You might want to implement actual git contribution tracking
            local contributions = {}
            for i = 1, 40 do
                table.insert(contributions, math.random(0, 4))
            end

            local contribution_str = {}
            for _, level in ipairs(contributions) do
                local chars = {" ", "▁", "▂", "▃", "▄", "█"}
                table.insert(contribution_str, chars[level + 1])
            end

            return table.concat(contribution_str)
        end

        dashboard.section.footer.val = {"Git Contributions: " .. get_git_contributions(), ""}

        -- Custom configuration
        dashboard.config.layout = {{
            type = "padding",
            val = 2
        }, dashboard.section.header, {
            type = "padding",
            val = 2
        }, dashboard.section.buttons, {
            type = "padding",
            val = 1
        }, dashboard.section.footer}

        alpha.setup(dashboard.config)

        vim.api.nvim_create_autocmd("AlphaReady", {
            callback = function()
                vim.opt.mousescroll = "ver:0,hor:0"
            end
        })

        vim.api.nvim_create_autocmd("AlphaClosed", {
            callback = function()
                vim.opt.mousescroll = "ver:1,hor:1"
            end
        })
    end
}}

return M

