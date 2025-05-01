local M = {}

M.plugins = {{
    'echasnovski/mini.notify',
    lazy = false,
    priority = 100,
    config = function()
        require('mini.notify').setup()
    end
}}

return M
