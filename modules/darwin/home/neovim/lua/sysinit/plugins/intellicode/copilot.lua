local M = {}

M.plugins = {{
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
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

