local M = {}

M.plugins = {{
    "goolord/alpha-nvim",
    lazy = false,
    priority = 99,
    dependencies = {"nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim", "rgmatti/auto-session"},
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

        -- Override the draw function to add error handling for window issues
        local alpha_draw_orig = alpha.draw
        alpha.draw = function(...)
            local status, err = pcall(alpha_draw_orig, ...)
            if not status then
                -- Silently handle window errors
                if string.match(tostring(err), "Invalid window id") then
                    return
                end
                -- Re-raise other errors
                error(err)
            end
        end

        alpha.setup(dashboard.config)

        -- Create Alpha UI state manager
        local alpha_ui = {
            -- Store original UI values
            state = {},

            -- Save current UI state with proper value retrieval
            save = function()
                return {
                    showtabline = vim.opt.showtabline:get(),
                    ruler = vim.opt.ruler:get(),
                    laststatus = vim.opt.laststatus:get(),
                    number = vim.opt.number:get(),
                    relativenumber = vim.opt.relativenumber:get(),
                    signcolumn = vim.opt.signcolumn:get(),
                    mousescroll = vim.opt.mousescroll:get(),
                    guicursor = vim.opt.guicursor:get()
                }
            end,

            -- Apply Alpha-specific UI settings
            apply = function()
                vim.opt.showtabline = 0
                vim.opt.ruler = false
                vim.opt.laststatus = 0
                vim.opt.number = false
                vim.opt.relativenumber = false
                vim.opt.signcolumn = "no"
                vim.opt.mousescroll = "ver:0,hor:0"
                vim.opt.guicursor = "n:none"
            end,

            -- Restore saved UI state
            restore = function(saved_state)
                for option, value in pairs(saved_state) do
                    -- Use pcall for error handling
                    pcall(function()
                        vim.opt[option] = value
                    end)
                end
            end
        }

        -- Create an augroup for Alpha UI management
        local alpha_ui_group = vim.api.nvim_create_augroup("AlphaUI", {
            clear = true
        })

        -- When Alpha is ready, save state and apply Alpha UI
        vim.api.nvim_create_autocmd("User", {
            group = alpha_ui_group,
            pattern = "AlphaReady",
            callback = function()
                -- Store the state in buffer-local variable for reliability
                local buf = vim.api.nvim_get_current_buf()
                -- Save the state first
                vim.b[buf].alpha_ui_saved_state = alpha_ui.save()
                -- Then apply Alpha UI settings
                alpha_ui.apply()
            end
        })

        -- When Alpha is closed, restore UI from saved state
        vim.api.nvim_create_autocmd("User", {
            group = alpha_ui_group,
            pattern = "AlphaClosed",
            callback = function()
                -- Get the buffer where state was saved
                local bufs = vim.api.nvim_list_bufs()
                for _, buf in ipairs(bufs) do
                    -- If this buffer has saved state, restore from it
                    if vim.b[buf] and vim.b[buf].alpha_ui_saved_state then
                        alpha_ui.restore(vim.b[buf].alpha_ui_saved_state)
                        -- Clear the saved state to avoid potential issues
                        vim.b[buf].alpha_ui_saved_state = nil
                        break
                    end
                end
            end
        })

        vim.api.nvim_create_autocmd("VimEnter", {
            pattern = "*",
            callback = function()
                vim.cmd("Alpha")
            end
        })

        vim.api.nvim_create_augroup("alpha_on_empty", {
            clear = true
        })
        vim.api.nvim_create_autocmd("User", {
            pattern = "BDeletePost*",
            group = "alpha_on_empty",
            callback = function(event)
                local fallback_name = vim.api.nvim_buf_get_name(event.buf)
                local fallback_ft = vim.api.nvim_buf_get_option(event.buf, "filetype")
                local fallback_on_empty = fallback_name == "" and fallback_ft == ""

                if fallback_on_empty then
                    pcall(function()
                        vim.cmd("Alpha")
                    end)
                end
            end
        })
    end
}}

return M
