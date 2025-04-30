local M = {}

M.plugins = {{
    "goolord/alpha-nvim",
    dependencies = {"3rd/image.nvim", "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim"},
    opts = {
        rocks = {
            hererocks = true
        }
    },
    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")
        local win_width = vim.o.columns

        local function read_ascii_art()
            -- load alpha.ascii next to init.lua, else use embedded art
            local cfg = vim.fn.fnamemodify(vim.fn.expand("$MYVIMRC"), ":p:h")
            -- try ascii next to init.lua
            local ascii_path = cfg .. "/alpha.ascii"
            if vim.loop.fs_stat(ascii_path) then
                return vim.fn.readfile(ascii_path)
            end
            -- try ascii in parent directory (one level up)
            local parent_path = vim.fn.fnamemodify(cfg, ":h") .. "/alpha.ascii"
            if vim.loop.fs_stat(parent_path) then
                return vim.fn.readfile(parent_path)
            end
            -- try ascii in grandparent directory (project root)
            local grand_path = vim.fn.fnamemodify(cfg, ":h:h") .. "/alpha.ascii"
            if vim.loop.fs_stat(grand_path) then
                return vim.fn.readfile(grand_path)
            end
            return
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
        end

        -- Set header
        dashboard.section.header.val = read_ascii_art()
        dashboard.section.header.opts.hl = "ProfileGreen"

        -- Set menu
        dashboard.section.buttons.val = {dashboard.button("a", "  Load Last Session", ":SessionRestore<CR>"),
                                         dashboard.button("f", "  Find Files", ":Telescope find_files<CR>"),
                                         dashboard.button("r", "  Recent Files", ":Telescope oldfiles<CR>"),
                                         dashboard.button("g", "  Live Grep", ":Telescope live_grep<CR>"),
                                         dashboard.button("c", "  Configuration", ":e $MYVIMRC<CR>"),
                                         dashboard.button("t", "  Change Theme", ":Themify<CR>"),
                                         dashboard.button("l", "  Lazy", ":Lazy<CR>"),
                                         dashboard.button("q", "  Quit", ":qa<CR>")}

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

        dashboard.section.footer.val = {"Git Contributions: " .. get_git_contributions(), "Welcome back, Roshan"}

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

        -- Disable folding on alpha buffer
        vim.cmd([[
        autocmd FileType alpha setlocal nofoldenable
      ]])

        -- Setup alpha
        alpha.setup(dashboard.config)
    end
}}

function M.setup()
    vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
            vim.opt_local.scrolloff = 0
            vim.opt_local.sidescrolloff = 0

            vim.api.nvim_set_hl(0, "ProfileBlue", {
                fg = "#61afef",
                bold = true
            })
            vim.api.nvim_set_hl(0, "ProfileGreen", {
                fg = "#98c379",
                bold = true
            })
            vim.api.nvim_set_hl(0, "ProfileYellow", {
                fg = "#e5c07b",
                bold = true
            })
            vim.api.nvim_set_hl(0, "ProfileRed", {
                fg = "#e06c75",
                bold = true
            })
        end
    })
end

return M

