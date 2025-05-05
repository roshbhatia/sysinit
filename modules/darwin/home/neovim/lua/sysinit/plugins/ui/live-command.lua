local M = {}

M.plugins = {{
    "smjonas/live-command.nvim",
    lazy = false,
    opts = {
        commands = {
            Norm = {
                cmd = "norm"
            }
        }
    }
}}

return M
