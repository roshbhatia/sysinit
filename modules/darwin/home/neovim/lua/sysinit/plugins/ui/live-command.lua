local M = {}

M.plugins = {{
    "smjonas/live-command.nvim",
    lazy = false,
    config = function()
        require("live-command").setup()
    end
}}

return M
