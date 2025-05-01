local M = {}

M.plugins = {{
    'echasnovski/mini.notify',
    lazy = false,
    priority = 100,
    config = function()
        require('mini.notify').setup({
            lsp_progress = {
                enable = false
            }
        })
        vim.api.nvim_set_hl(0, "MiniNotifyBorder", {
            link = "NormalFloat"
        })
        vim.api.nvim_set_hl(0, "MiniNotifyNormal", {
            link = "NormalFloat"
        })
        vim.api.nvim_set_hl(0, "MiniNotifyTitle", {
            link = "NormalFloat"
        })
    end
}}

return M
