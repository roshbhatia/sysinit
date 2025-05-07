local M = {}

M.plugins = {
    {
        "goolord/alpha-nvim",
        event = "VimEnter",
        enabled = true, -- Always enable
        dependencies = {
            "nvim-tree/nvim-web-devicons",
            "rmagatti/auto-session" -- Add session management dependency
        },
        config = function()
            local alpha = require("alpha")
            local dashboard = require("alpha.themes.dashboard")

            dashboard.section.header.val = {
                [[⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
                [[⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
                [[⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
                [[⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠉⠄⠄⠄⠄⠄⠄⠉⠉⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
                [[⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠁⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
                [[⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠁⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠈⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
                [[⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⣀⣤⣤⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
                [[⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠄⢀⣠⣶⣶⣦⣤⣀⠄⠄⠄⠄⠄⠄⠄⠄⢀⣴⣿⡿⠿⠛⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
                [[⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⠄⢀⣾⡿⠛⠙⠉⠉⠙⠻⣷⡄⠄⠄⠄⠄⣰⡿⠋⠁⠄⠄⠄⠄⠄⠉⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
                [[⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⠄⠄⣼⡿⠄⠄⠄⠄⠄⠄⠄⢸⣷⠄⠄⠄⢰⣿⠁⠄⠄⠄⠄⠄⠄⠄⠄⠄⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
                [[⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠄⠄⣿⡇⠄⠄⠄⠄⠄⠄⠄⢸⣿⠄⠄⠄⢸⣿⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
                [[⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠄⠄⣿⡇⠄⠄⠄⠄⠄⠄⠄⢸⣿⡀⠄⠄⢸⣿⡇⠄⠄⠄⠄⠄⠄⠄⠄⠄⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
                [[⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠄⠄⢿⣷⠄⠄⠄⠄⠄⠄⠄⣼⣿⣇⠄⠄⠈⣿⣇⠄⠄⠄⠄⠄⠄⠄⠄⠄⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
                [[⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠄⠄⠘⣿⣆⠄⠄⠄⠄⠄⣼⣿⣿⣿⡀⠄⠄⠘⣿⣦⡀⠄⠄⠄⠄⠄⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
                [[⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⡀⠄⠈⠻⢷⣦⣤⣤⣾⡿⠋⠄⠻⣧⠄⠄⠄⠈⠙⠿⢷⣶⣶⣶⡿⠿⠋⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
                [[⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣄⡀⠄⠄⠉⠉⠉⠄⠄⠄⠄⣿⣧⣀⡀⠄⠄⠄⠄⠄⠄⠄⠄⠄⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
                [[⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣦⣤⣤⣤⣴⣶⣿⣿⣿⣿⣿⣷⣶⣶⣶⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿]]
            }

            dashboard.section.header.opts = {
                position = "center",
                hl = "DashboardHeader"
            }

            -- Add session loading button
            dashboard.section.buttons.val = {
                dashboard.button("s", "  Load last session", ":lua require('auto-session').RestoreSession()<CR>"),
                dashboard.button("f", "  Find file", ":Telescope find_files<CR>"),
                dashboard.button("e", "  New file", ":ene <BAR> startinsert<CR>"),
                dashboard.button("p", "  Find project", ":Telescope projects<CR>"),
                dashboard.button("r", "  Recently used files", ":Telescope oldfiles<CR>"),
                dashboard.button("t", "  Find text", ":Telescope live_grep<CR>"),
                dashboard.button("c", "  Configuration", ":e $MYVIMRC<CR>"),
                dashboard.button("q", "  Quit Neovim", ":qa<CR>")
            }

            local function footer()
                local stats = require("lazy").stats()
                local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
                return "⚡ Neovim loaded " .. stats.count .. " plugins in " .. ms .. "ms"
            end

            dashboard.section.footer.val = footer()
            dashboard.section.footer.opts.hl = "DashboardFooter"
            dashboard.section.buttons.opts.hl = "DashboardCenter"
            dashboard.opts.layout = {
                {
                    type = "padding",
                    val = 4
                },
                dashboard.section.header,
                {
                    type = "padding",
                    val = 2
                },
                dashboard.section.buttons,
                {
                    type = "padding",
                    val = 2
                },
                dashboard.section.footer
            }

            -- Safe redraw function
            local alpha_redraw = function()
                -- Only update if the dashboard buffer exists and is valid
                local bufnr = vim.fn.bufnr('dashboard')
                if bufnr and bufnr ~= -1 and vim.api.nvim_buf_is_valid(bufnr) then
                    dashboard.section.footer.val = footer()
                    pcall(vim.cmd.AlphaRedraw)
                end
            end

            -- Hide UI elements when Alpha is open
            local function hide_ui_on_alpha()
                local alpha_buf = vim.api.nvim_get_current_buf()
                local is_alpha = vim.api.nvim_buf_get_option(alpha_buf, 'filetype') == 'alpha'
                
                if is_alpha then
                    -- Hide tabline
                    vim.opt.showtabline = 0
                    -- Hide statusline
                    vim.opt.laststatus = 0
                    -- Close any neo-tree or explorer windows
                    pcall(vim.cmd, "Neotree close")
                else
                    -- Restore normal settings when not on Alpha
                    vim.opt.showtabline = 2
                    vim.opt.laststatus = 3
                end
            end

            -- Create autocmd group for Alpha customizations
            vim.api.nvim_create_augroup("alpha_customizations", {
                clear = true
            })

            -- Hide UI elements when entering Alpha
            vim.api.nvim_create_autocmd({"FileType", "BufEnter", "BufWinEnter"}, {
                group = "alpha_customizations",
                callback = hide_ui_on_alpha
            })

            -- Auto-start Alpha when no args and no buffers
            vim.api.nvim_create_augroup("alpha_autostart", {
                clear = true
            })

            -- Always show Alpha on startup
            vim.api.nvim_create_autocmd("VimEnter", {
                group = "alpha_autostart",
                callback = function()
                    -- Only start Alpha if we should not skip it
                    pcall(function()
                        require('alpha').start(true)
                        vim.cmd("AlphaFooter")
                        hide_ui_on_alpha()
                    end)
                end,
                desc = "Start Alpha when Neovim is opened"
            })

            -- Setup alpha
            alpha.setup(dashboard.opts)

            -- Prevent window resize errors
            vim.api.nvim_create_autocmd("WinResized", {
                callback = function()
                    pcall(alpha_redraw)
                end,
                desc = "Safely redraw Alpha dashboard on window resize"
            })
        end
    }
}

return M