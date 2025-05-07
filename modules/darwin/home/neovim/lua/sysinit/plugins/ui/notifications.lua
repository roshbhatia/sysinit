local M = {}

M.plugins = {
    {
        "j-hui/fidget.nvim",
        event = "LspAttach",
        opts = {
            -- Options for the Fidget notification system
            notification = {
                -- Visual customization
                window = {
                    winblend = 0,         -- No transparency
                    border = "rounded",   -- Rounded borders
                    max_width = 80,       -- Maximum width of the notification window
                    max_height = 40,      -- Maximum height of the notification window
                    zindex = 45,          -- Make sure it stays on top of other windows
                },
                view = {
                    stack_upwards = true, -- New notifications appear at the bottom
                    icon_separator = " ", -- Separator between the icon and the title
                    group_separator = "---", -- Separator between notification groups
                },
                -- How notifications are displayed
                display = {
                    render_limit = 10,    -- Maximum number of notifications to show
                    timeout = 10,         -- How long notifications stay on screen (seconds)
                    icon_spacing = 1,     -- Spacing between icon and text
                    stack_messages = true, -- Group similar messages
                },
            },
            -- LSP progress subsystem options
            progress = {
                poll_rate = 0.2,          -- How frequently to poll for progress updates (seconds)
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
                -- Formatting and appearance
                format_message = require("fidget.progress.display").default_format_message, 
                format_annote = function(msg)
                    -- Format the annotation as [lsp_client_name]
                    return msg.lsp_client.name
                end,
                format_group_name = function(group)
                    -- Format the group name as [LSP] lsp_client_name
                    return "[LSP] " .. group
                end,                
                -- Icons for different LSP progress states
                icon_style = "bright",  -- Use bright colored icons
                -- Define spinner animation
                spinner = {
                    "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"
                },
            },
            -- Ensure the notifications are accessible
            integration = {
                ["nvim-tree"] = {
                    enable = true,        -- Offset notifications when nvim-tree is open
                },
                ["xcodebuild"] = {
                    enable = true,
                },
            },
            -- Command history options
            logger = {
                level = vim.log.levels.INFO, -- Minimum log level
                max_size = 10000,          -- Maximum number of entries to keep
                float_precision = 0.01,    -- Precision for float values in logs
            },
        },
        -- Configure commands after plugin is loaded
        config = function(_, opts)
            require("fidget").setup(opts)
            
            -- Add commands for notification history
            vim.api.nvim_create_user_command("FidgetClear", function()
                require("fidget.notification").clear()
            end, { desc = "Clear Fidget notifications" })
            
            vim.api.nvim_create_user_command("FidgetHistory", function()
                require("fidget.notification").show_history()
            end, { desc = "Show Fidget notification history" })
        end
    }
}

return M