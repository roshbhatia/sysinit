local M = {}

M.plugins = {{
    "j-hui/fidget.nvim",
    opts = {},
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
            desc = "Notifications: clear"
        }}
    end
}}

return M
