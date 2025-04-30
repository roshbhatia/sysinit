local M = {}

M.plugins = {{
    "APZelos/blamer.nvim",
    commit = "e0d43c11697300eb68f00d69df8b87deb0bf52dc",
    lazy = false,
    config = function()
        vim.g.blamer_enabled = true
        vim.g.blamer_delay = 50
        vim.g.blamer_show_in_insert_modes = 0
        vim.g.blamer_show_in_visual_modes = 1
        vim.g.blamer_prefix = ' ﰲ '
        vim.g.blamer_template = '<author>, <author-time> • <summary>'
        vim.g.blamer_date_format = '%Y-%m-%d %H:%M'
        vim.g.blamer_relative_time = 1
    end
}}

return M
