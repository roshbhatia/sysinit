local M = {}

M.plugins = {{
    'phaazon/hop.nvim',
    lazy = true,
    config = function()
        local hop = require('hop')
        hop.setup({
            keys = 'fjdkslaghrueiwoncmv',
            jump_on_sole_occurrence = true,
            case_sensitive = false
        })

        vim.keymap.set('n', '<S-Enter>', '<cmd>HopWord<CR>', {
            noremap = true,
            silent = true
        })
        vim.keymap.set('i', '<S-Enter>', '<Esc><cmd>HopWord<CR>', {
            noremap = true,
            silent = true
        })
        vim.keymap.set('n', '<leader>j', '<cmd>HopWord<CR>', {
            noremap = true,
            silent = true
        })

        vim.keymap.set('n', '<leader>jj', '<cmd>HopWord<CR>', {
            noremap = true,
            silent = true
        })
        vim.keymap.set('n', '<leader>jl', '<cmd>HopLine<CR>', {
            noremap = true,
            silent = true
        })
        vim.keymap.set('n', '<leader>js', '<cmd>HopChar1<CR>', {
            noremap = true,
            silent = true
        })
        vim.keymap.set('n', '<leader>jp', '<cmd>HopPattern<CR>', {
            noremap = true,
            silent = true
        })
    end
}}

return M
