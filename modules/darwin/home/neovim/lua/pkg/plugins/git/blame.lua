local plugin_family = {}

M.plugins = {{
    "APZelos/blamer.nvim",
    lazy = false,
    config = function()
        vim.g.blamer_enabled = true
        vim.g.blamer_delay = 50
        vim.g.blamer_show_in_insert_modes = 0
        vim.g.blamer_show_in_visual_modes = 1
        vim.g.blamer_prefix = ' ﰲ '
        vim.g.blamer_template = '<author>, <author-time> • <summary>'
        vim.g.blamer_date_format = '%Y-%m-%d'
        vim.g.blamer_relative_time = 1
    end
}}

return plugin_family
