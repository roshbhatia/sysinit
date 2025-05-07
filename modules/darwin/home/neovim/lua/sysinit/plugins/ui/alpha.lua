local M = {}

M.plugins = {{
    "goolord/alpha-nvim",
    event = "VimEnter",
    enabled = function()
        return not vim.g.vscode
    end,
    dependencies = {"nvim-tree/nvim-web-devicons"},
    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")

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

        dashboard.section.header.opts = {
            position = "center",
            hl = "DashboardHeader"
        }

        dashboard.section.buttons.val = {dashboard.button("f", "  Find file", ":Telescope find_files <CR>"),
                                         dashboard.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
                                         dashboard.button("p", "  Find project", ":Telescope projects <CR>"),
                                         dashboard.button("r", "  Recently used files", ":Telescope oldfiles <CR>"),
                                         dashboard.button("t", "  Find text", ":Telescope live_grep <CR>"),
                                         dashboard.button("c", "  Configuration", ":e $MYVIMRC <CR>"),
                                         dashboard.button("q", "  Quit Neovim", ":qa<CR>")}

        local function footer()
            local stats = require("lazy").stats()
            local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
            return "⚡ Neovim loaded " .. stats.count .. " plugins in " .. ms .. "ms"
        end

        dashboard.section.footer.val = footer()
        dashboard.section.footer.opts.hl = "DashboardFooter"
        dashboard.section.buttons.opts.hl = "DashboardCenter"
        dashboard.opts.layout = {{
            type = "padding",
            val = 4
        }, dashboard.section.header, {
            type = "padding",
            val = 2
        }, dashboard.section.buttons, {
            type = "padding",
            val = 2
        }, dashboard.section.footer}

        -- Use protected calls for Alpha to prevent errors
        alpha.setup(dashboard.opts)

        -- Safe redraw function that won't break when buffer doesn't exist
        local alpha_redraw = function()
            -- Only update if the dashboard buffer exists and is visible
            local bufnr = vim.fn.bufnr('dashboard')
            if bufnr and bufnr ~= -1 and vim.api.nvim_buf_is_valid(bufnr) then
                dashboard.section.footer.val = footer()
                pcall(vim.cmd.AlphaRedraw)
            end
        end

        -- Auto-start Alpha when no args and no buffers
        vim.api.nvim_create_augroup("alpha_autostart", {
            clear = true
        })

        -- Safely update dashboard stats when lazy.nvim completes loading
        vim.api.nvim_create_autocmd("User", {
            pattern = "LazyVimStarted",
            callback = function()
                pcall(alpha_redraw)
            end
        })

        -- Only show dashboard when starting Neovim with no arguments
        vim.api.nvim_create_autocmd("VimEnter", {
            group = "alpha_autostart",
            callback = function()
                local should_skip = false
                -- Check if there are files specified on the command line
                if vim.fn.argc() > 0 or vim.fn.line2byte('$') ~= -1 or not vim.o.modifiable then
                    should_skip = true
                else
                    -- Check for command line arguments that would indicate we shouldn't show Alpha
                    for _, arg in pairs(vim.v.argv) do
                        if arg == "-b" or arg == "-c" or vim.startswith(arg, "+") or arg == "-S" then
                            should_skip = true
                            break
                        end
                    end
                end

                -- Only start Alpha if we should not skip it
                if not should_skip then
                    -- Use pcall to prevent errors if Alpha can't start for some reason
                    pcall(function()
                        require('alpha').start(true)
                        vim.cmd("AlphaFooter")
                    end)
                end
            end,
            desc = "Start Alpha when Neovim is opened with no arguments"
        })

        -- Add protection against window resize errors
        vim.api.nvim_create_autocmd("WinResized", {
            callback = function()
                pcall(alpha_redraw)
            end,
            desc = "Safely redraw Alpha dashboard on window resize"
        })
    end
}}

return M
