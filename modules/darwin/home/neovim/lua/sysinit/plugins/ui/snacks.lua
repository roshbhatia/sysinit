local M = {}

M.plugins = {{
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
        bigfile = {
            enabled = true
        },
        dashboard = {
            enabled = false
        },
        explorer = {
            enabled = false
        },
        indent = {
            enabled = false
        },
        input = {
            enabled = false
        },
        picker = {
            enabled = true
        },
        notifier = {
            enabled = false
        },
        quickfile = {
            enabled = false
        },
        scope = {
            enabled = false
        },
        scroll = {
            enabled = false
        },
        statuscolumn = {
            enabled = false
        },
        words = {
            enabled = false
        }
    }
}}

return M
