local M = {}

M.plugins = {{
    "rmagatti/auto-session",
    lazy = false,
    priority = 10, -- Load early to ensure session restoration works properly
    opts = {
        log_level = "error",
        auto_session_enable_last_session = false,
        auto_session_root_dir = vim.fn.stdpath("data") .. "/sessions/",
        auto_session_enabled = true,
        auto_save_enabled = true,
        auto_restore_enabled = false,
        auto_session_use_git_branch = true,
        -- Don't save these buffers/directories in the session
        auto_session_suppress_dirs = {"~/", "~/Downloads", "~/Documents"},
        bypass_session_save_file_types = {"alpha", "NvimTree", "neo-tree", "qf", "help", "nofile"},
        pre_save_cmds = { -- Close things that shouldn't be saved before saving the session
        "Neotree close", function()
            -- Hide the statusline and tabline
            -- This helps when restoring sessions
            vim.opt.showtabline = 0
            vim.opt.laststatus = 0
        end},
        post_restore_cmds = {function()
            -- Ensure UI elements are properly initialized after session restore
            vim.defer_fn(function()
                if vim.bo.filetype ~= "alpha" then
                    vim.opt.showtabline = 2
                    vim.opt.laststatus = 3
                end
            end, 100)
        end}
    },
    config = function(_, opts)
        local auto_session = require("auto-session")
        auto_session.setup(opts)

        -- Create commands for session management
        vim.api.nvim_create_user_command("SessionSave", function()
            auto_session.SaveSession()
        end, {
            desc = "Save session"
        })

        vim.api.nvim_create_user_command("SessionRestore", function()
            auto_session.RestoreSession()
        end, {
            desc = "Restore session"
        })

        vim.api.nvim_create_user_command("SessionDelete", function()
            auto_session.DeleteSession()
        end, {
            desc = "Delete current session"
        })

        -- Add commands to help with session management in alpha dashboard
        vim.api.nvim_create_autocmd("User", {
            pattern = "AlphaReady",
            callback = function()
                -- If we just restored a session, show a notification
                local session_file = auto_session.current_session_name
                if session_file and vim.fn.filereadable(session_file) == 1 then
                    vim.defer_fn(function()
                        vim.notify("Session restored: " .. vim.fn.fnamemodify(session_file, ":t:r"), vim.log.levels.INFO)
                    end, 500)
                end
            end
        })
    end
}}

return M
