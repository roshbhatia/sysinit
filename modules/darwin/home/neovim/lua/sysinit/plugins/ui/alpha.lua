local M = {}

M.plugins = { {
    "goolord/alpha-nvim",
    lazy = false,
    priority = 100,
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")
        local win_width = vim.o.columns

        -- Set header
        dashboard.section.header.val =
        { "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣄⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
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
            "" }
        local auto_session = require("auto-session")

        dashboard.section.header.opts.hl = "ProfileRed"

        -- Set menu with conditional session button
        dashboard.section.buttons.val = { require('auto-session.lib').current_session_name(true) and
        dashboard.button("a", "  Load Last Session", ":SessionRestore<CR>") or nil,
            dashboard.button("i", "  Init Buffer", ":enew<CR>"),
            dashboard.button("f", "  Find Files", ":Telescope find_files<CR>"),
            dashboard.button("r", "  Recent Files", ":Telescope oldfiles<CR>"),
            dashboard.button("g", "  Live Grep", ":Telescope live_grep<CR>"),
            dashboard.button("q", "  Quit", ":qa<CR>") }

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
                local chars = { " ", "▁", "▂", "▃", "▄", "█" }
                table.insert(contribution_str, chars[level + 1])
            end

            return table.concat(contribution_str)
        end

        dashboard.section.footer.val = { "Git Contributions: " .. get_git_contributions(), "" }

        -- Custom configuration
        dashboard.config.layout = { {
            type = "padding",
            val = 2
        }, dashboard.section.header, {
            type = "padding",
            val = 2
        }, dashboard.section.buttons, {
            type = "padding",
            val = 1
        }, dashboard.section.footer }

        alpha.setup(dashboard.config)

        vim._alpha_ui = {
            state = {},
            restore = function()
                for option, value in pairs(vim._alpha_ui.state) do
                    vim.opt[option] = value
                end
            end
        }

        vim.api.nvim_create_autocmd("User", {
            pattern = "AlphaReady",
            callback = function()
                vim._alpha_ui.state = {
                    showtabline = vim.opt.showtabline:get(),
                    ruler = vim.opt.ruler:get(),
                    laststatus = vim.opt.laststatus:get(),
                    number = vim.opt.number:get(),
                    relativenumber = vim.opt.relativenumber:get(),
                    signcolumn = vim.opt.signcolumn:get(),
                    mousescroll = vim.opt.mousescroll:get(),
                    guicursor = vim.opt.guicursor:get()
                }
                vim.opt.showtabline = 0
                vim.opt.ruler = false
                vim.opt.laststatus = 0
                vim.opt.number = false
                vim.opt.relativenumber = false
                vim.opt.signcolumn = "no"
                vim.opt.mousescroll = "ver:0,hor:0"
                vim.opt.guicursor = "n:none"
            end
        })

        vim.api.nvim_create_autocmd("User", {
            pattern = "AlphaClosed",
            callback = function()
                vim._alpha_ui.restore()
            end
        })

        vim.api.nvim_create_autocmd("VimEnter", {
            pattern = "*",
            callback = function()
                vim.cmd("Alpha")
            end
        })

        vim.api.nvim_create_augroup("alpha_on_empty", { clear = true })
        vim.api.nvim_create_autocmd("User", {
            pattern = "BDeletePost*",
            group = "alpha_on_empty",
            callback = function(event)
                local fallback_name = vim.api.nvim_buf_get_name(event.buf)
                local fallback_ft = vim.api.nvim_buf_get_option(event.buf, "filetype")
                local fallback_on_empty = fallback_name == "" and fallback_ft == ""

                if fallback_on_empty then
                    vim.cmd("Alpha")
                end
            end,
        })
    end
} }

return M
