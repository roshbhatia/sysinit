local M = {}

M.plugins = {{
    "j-hui/fidget.nvim",
    event = "VimEnter", -- Load earlier so it's available for all notifications
    opts = {
        -- Options related to LSP progress subsystem
        progress = {
            poll_rate = 0.2, -- How frequently to poll for progress updates (seconds)
            suppress_on_insert = false, -- Whether to suppress notifications in insert mode
            ignore_done_already = true, -- Ignore 'done' when already complete
            ignore_empty_message = true, -- Ignore empty messages
            clear_on_detach = function(client_id)
                -- Only clear notifications when LSP client is explicitly detached
                local client = vim.lsp.get_client_by_id(client_id)
                return client and client.name or nil
            end,
            notification_group = function(msg)
                -- Group by client name
                return msg.lsp_client.name
            end,
            -- Formatting and appearance options for LSP progress
            display = {
                render_limit = 16, -- How many LSP messages to show at once
                done_ttl = 3, -- How long a message should persist after completion
                done_icon = "✓", -- Icon shown when all LSP progress tasks are complete
                done_style = "Constant", -- Highlight group for completed LSP tasks
                progress_ttl = math.huge, -- How long a message should persist when in progress
                progress_icon = {"dots"}, -- Icon shown when LSP progress tasks are in progress
                progress_style = "WarningMsg", -- Highlight group for in-progress LSP tasks
                group_style = "Title", -- Highlight group for group name (LSP server name)
                icon_style = "Question", -- Highlight group for group icons
                priority = 30, -- Ordering priority for LSP notification group
                skip_history = true -- Whether progress notifications should be omitted from history
            }
        },

        -- Options for the notification subsystem
        notification = {
            poll_rate = 10, -- How frequently to update and render notifications
            filter = vim.log.levels.INFO, -- Minimum notifications level
            history_size = 128, -- Number of removed messages to retain in history
            override_vim_notify = true, -- Set to true to make Fidget the backend for all notifications

            -- Options related to how notifications are rendered as text
            view = {
                stack_upwards = true, -- Display notification items from bottom to top
                icon_separator = " ", -- Separator between group name and icon
                group_separator = "---", -- Separator between notification groups
                group_separator_hl = "Comment" -- Highlight group used for group separator
            },

            -- Options related to the notification window and buffer
            window = {
                normal_hl = "Comment", -- Base highlight group in the notification window
                winblend = 0, -- Background color opacity in the notification window
                border = "rounded", -- Border around the notification window
                zindex = 45, -- Stacking priority of the notification window
                max_width = 80, -- Maximum width of the notification window
                max_height = 40, -- Maximum height of the notification window
                x_padding = 1, -- Padding from right edge of window boundary
                y_padding = 0, -- Padding from bottom edge of window boundary
                align = "bottom", -- How to align the notification window
                relative = "editor" -- What the notification window position is relative to
            },

            -- Configure how different notification levels appear
            configs = {
                default = {
                    name = "Notifications", -- Default group name
                    icon = "󰂚", -- Default icon
                    ttl = 5, -- Default time-to-live
                    group = "General", -- Default group
                    icon_hl = "Special" -- Highlight for icons
                },
                debug = {
                    name = "Debug",
                    icon = "󰃤",
                    ttl = 3,
                    group = "Debug",
                    icon_hl = "Debug"
                },
                info = {
                    name = "Info",
                    icon = "󰋼",
                    ttl = 5,
                    group = "Info",
                    icon_hl = "DiagnosticInfo"
                },
                warn = {
                    name = "Warning",
                    icon = "󰀦",
                    ttl = 8,
                    group = "Warnings",
                    icon_hl = "DiagnosticWarn"
                },
                error = {
                    name = "Error",
                    icon = "󰅚",
                    ttl = 10,
                    group = "Errors",
                    icon_hl = "DiagnosticError"
                }
            }
        },

        integration = {},

        -- Options related to logging
        logger = {
            level = vim.log.levels.INFO, -- Minimum log level
            max_size = 10000, -- Maximum number of entries to keep
            float_precision = 0.01 -- Precision for float values in logs
        }
    },
    -- Configure commands after plugin is loaded
    config = function(_, opts)
        require("fidget").setup(opts)

        -- Add commands for notification history
        vim.api.nvim_create_user_command("FidgetClear", function()
            require("fidget.notification").clear()
        end, {
            desc = "Clear Fidget notifications"
        })

        vim.api.nvim_create_user_command("FidgetHistory", function()
            require("fidget.notification").show_history()
        end, {
            desc = "Show Fidget notification history"
        })

        -- Load Telescope extension if available
        local ok, telescope = pcall(require, "telescope")
        if ok then
            pcall(telescope.load_extension, "fidget")
        end

        -- Create a convenience function to show notifications
        _G.notify = function(msg, level, opts)
            return vim.notify(msg, level, opts)
        end
    end,
    keys = function()
        return {{
            "<leader>ns",
            function()
                require("fidget.notification").show_history()
            end,
            desc = "Notifications: show"
        }, {
            "<leader>nc",
            function()
                require("fidget.notification").clear()
            end,
            desc = "Notifications:clear"
        }}
    end
}}

return M
