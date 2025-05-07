local M = {}

M.plugins = {
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        cmd = { "ToggleTerm", "TermExec" },
        keys = {
            { "<leader>tt", "<cmd>ToggleTerm<CR>", desc = "Toggle Terminal" },
            { "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", desc = "Toggle Float Terminal" },
            { "<leader>th", "<cmd>ToggleTerm direction=horizontal<CR>", desc = "Toggle Horizontal Terminal" },
            { "<leader>tv", "<cmd>ToggleTerm direction=vertical<CR>", desc = "Toggle Vertical Terminal" },
        },
        opts = {
            size = function(term)
                if term.direction == "horizontal" then
                    return 15
                elseif term.direction == "vertical" then
                    return vim.o.columns * 0.4
                end
            end,
            open_mapping = [[<c-\>]],
            hide_numbers = true,
            shade_filetypes = {},
            shade_terminals = true,
            shading_factor = 2,
            start_in_insert = true,
            insert_mappings = true,
            persist_size = true,
            direction = "float",
            close_on_exit = true,
            shell = vim.o.shell,
            float_opts = {
                border = "curved",
                winblend = 0,
                highlights = {
                    border = "Normal",
                    background = "Normal",
                }
            }
        },
        config = function(_, opts)
            require("toggleterm").setup(opts)
            
            -- Terminal keymaps when terminal is open
            function _G.set_terminal_keymaps()
                local bufmap = function(mode, lhs, rhs)
                    vim.keymap.set(mode, lhs, rhs, { buffer = 0 })
                end
                
                bufmap('t', '<esc>', [[<C-\><C-n>]])
                bufmap('t', 'jk', [[<C-\><C-n>]])
                bufmap('t', '<C-h>', [[<Cmd>wincmd h<CR>]])
                bufmap('t', '<C-j>', [[<Cmd>wincmd j<CR>]])
                bufmap('t', '<C-k>', [[<Cmd>wincmd k<CR>]])
                bufmap('t', '<C-l>', [[<Cmd>wincmd l<CR>]])
            end

            vim.api.nvim_create_autocmd("TermOpen", {
                pattern = "term://*",
                callback = function()
                    set_terminal_keymaps()
                end
            })
            
            -- Create custom terminal for lazygit and other tools
            local Terminal = require("toggleterm.terminal").Terminal
            
            -- Define lazygit terminal for quick access
            local lazygit = Terminal:new({
                cmd = "lazygit",
                hidden = true,
                direction = "float",
                float_opts = {
                    border = "curved",
                },
                on_open = function(term)
                    vim.cmd("startinsert!")
                    -- ESC twice to close in lazygit
                    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
                end,
            })

            -- Create command to open lazygit
            vim.api.nvim_create_user_command("LazyGitToggle", function()
                lazygit:toggle()
            end, {})
            
            -- Define node terminal for quick access
            local node = Terminal:new({
                cmd = "node",
                hidden = true,
                direction = "float",
                float_opts = {
                    border = "curved",
                },
            })

            vim.api.nvim_create_user_command("NodeToggle", function()
                node:toggle()
            end, {})
            
            -- Define python terminal for quick access
            local python = Terminal:new({
                cmd = "python3",
                hidden = true,
                direction = "float",
                float_opts = {
                    border = "curved",
                },
            })

            vim.api.nvim_create_user_command("PythonToggle", function()
                python:toggle()
            end, {})
        end
    }
}

return M