-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/rmagatti/auto-session/refs/heads/main/doc/auto-session.txt"
local M = {}

M.plugins = {{
    "rmagatti/auto-session",
    commit = "00334ee24b9a05001ad50221c8daffbeedaa0842",
    lazy = false,
    priority = 100, -- Make sure it loads early
    config = function()
        local auto_session = require("auto-session")

        -- Check if lualine is available
        local function is_lualine_available()
            local ok, lualine = pcall(require, "lualine")
            return ok and lualine
        end

        -- Make sure the session directories exist
        local session_dir = vim.fn.stdpath("data") .. "/sessions/"
        vim.fn.mkdir(session_dir, "p")

        -- Set sessionoptions before setup to ensure proper session saving
        vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

        auto_session.setup({
            log_level = "info", -- Change to debug if issues persist
            auto_session_root_dir = session_dir,
            auto_session_enable_last_session = true,
            auto_save = true,
            auto_restore = true,
            auto_session_suppress_dirs = {}, -- Don't suppress any dirs

            -- Make sure to close floating windows before saving
            pre_save_cmds = {function()
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    local config = vim.api.nvim_win_get_config(win)
                    if config.relative ~= "" then
                        vim.api.nvim_win_close(win, false)
                    end
                end
            end},

            -- Refresh UI components after restore, with proper delay to ensure components are initialized
            post_restore_cmds = {function()
                vim.defer_fn(function()
                    if is_lualine_available() then
                        require("lualine").refresh()
                    end
                end, 100) -- Small delay to ensure components are initialized
            end},

            -- Additional settings that help with common issues
            bypass_save_filetypes = {"alpha", "NvimTree", "neo-tree", "dashboard", "lazy"},
            close_unsupported_windows = true,
            args_allow_single_directory = true,
            continue_restore_on_error = true,
            -- Enable lazy.nvim support
            lazy_support = true
        })

        -- Add an autocommand to verify the session was saved on exit
        vim.api.nvim_create_autocmd("VimLeavePre", {
            callback = function()
                vim.cmd("SessionSave")
            end
        })
    end
}}

return M
