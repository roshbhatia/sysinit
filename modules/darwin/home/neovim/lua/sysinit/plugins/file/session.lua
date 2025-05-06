-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/rmagatti/auto-session/refs/heads/main/doc/auto-session.txt"
local M = {}

M.plugins = { {
    "rmagatti/auto-session",
    lazy = false,
    priority = 100,
    dependencies = { "nvim-lualine/lualine.nvim" },
    config = function()
        local auto_session = require("auto-session")

        -- Make sure the session directories exist
        local session_dir = vim.fn.stdpath("data") .. "/sessions/"
        vim.fn.mkdir(session_dir, "p")

        auto_session.setup({
            enabled = true,
            root_dir = vim.fn.stdpath("data") .. "/sessions/",
            auto_save = true,
            auto_restore = false,
            auto_create = true,
            suppressed_dirs = nil,
            allowed_dirs = nil,
            auto_restore_last_session = false,
            git_use_branch_name = false,
            git_auto_restore_on_branch_change = false,
            lazy_support = true,
            bypass_save_filetypes = { "alpha", "NvimTree", "neo-tree", "dashboard", "lazy" },
            close_unsupported_windows = true,
            args_allow_single_directory = true,
            args_allow_files_auto_save = false,
            continue_restore_on_error = true,
            show_auto_restore_notif = true,
            cwd_change_handling = false,
            lsp_stop_on_restore = false,
            restore_error_handler = nil,
            purge_after_minutes = 14400,
            log_level = "info",

            pre_save_cmds = { function()
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    local config = vim.api.nvim_win_get_config(win)
                    if config.relative ~= "" then
                        vim.api.nvim_win_close(win, false)
                    end
                end
            end },

            post_restore_cmds = { function()
                vim.defer_fn(function()
                    require("lualine").refresh()
                end, 100)
            end },

            session_lens = {
                load_on_setup = true,
                theme_conf = {},
                previewer = false,

                mappings = {
                    delete_session = { "i", "<C-D>" },
                    alternate_session = { "i", "<C-S>" },
                    copy_session = { "i", "<C-Y>" }
                },

                session_control = {
                    control_dir = vim.fn.stdpath("data") .. "/auto_session/",
                    control_filename = "session_control.json"
                }
            }
        })

        -- Add an autocommand to verify the session was saved on exit
        vim.api.nvim_create_autocmd("VimLeavePre", {
            callback = function()
                vim.cmd("SessionSave")
            end
        })
    end
} }

return M
