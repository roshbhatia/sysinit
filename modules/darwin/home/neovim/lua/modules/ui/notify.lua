local M = {}

M.plugins = {{
    "rcarriga/nvim-notify",
    lazy = false,
    priority = 100,
    config = function()
        local notify = require("notify")
        notify.setup({
            -- Default configuration
            background_colour = "NotifyBackground",
            fps = 30,
            icons = {
                DEBUG = "",
                ERROR = "",
                INFO = "",
                TRACE = "✎",
                WARN = ""
            },
            level = vim.log.levels.INFO,
            minimum_width = 50,
            render = "default",
            stages = "fade_in_slide_out",
            timeout = 3000, -- 3 seconds default timeout
            top_down = true
        })

        vim.notify = notify
    end
}}

return M
