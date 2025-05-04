local M = {}

M.plugins = {{
    "zbirenbaum/copilot.lua",
    lazy = false,
    opts = {
        suggestion = {
            enabled = false
        },
        panel = {
            enabled = false
        }
    }
}}

return M

