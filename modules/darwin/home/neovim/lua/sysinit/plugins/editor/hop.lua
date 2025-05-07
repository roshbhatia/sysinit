local M = {}

M.plugins = {{
    'phaazon/hop.nvim',
    lazy = false,
    config = function()
        local hop = require('hop')
        hop.setup({
            keys = 'fjdkslaghrueiwoncmv',
            jump_on_sole_occurrence = false,
            case_sensitive = false
        })

        vim.keymap.set('n', '<S-Enter>', '<cmd>HopWord<CR>', {
            noremap = true,
            silent = true,
            desc = "Quick jump to word"
        })
        vim.keymap.set('i', '<S-Enter>', '<Esc><cmd>HopWord<CR>', {
            noremap = true,
            silent = true,
            desc = "Exit insert and quick jump to word"
        })
        vim.keymap.set('n', '<leader>j', '<cmd>HopWord<CR>', {
            noremap = true,
            silent = true,
            desc = "Quick jump to word"
        })

        vim.keymap.set('n', '<leader>jj', '<cmd>HopWord<CR>', {
            noremap = true,
            silent = true,
            desc = "Jump to any word"
        })
        vim.keymap.set('n', '<leader>jl', '<cmd>HopLine<CR>', {
            noremap = true,
            silent = true,
            desc = "Jump to any line"
        })
        vim.keymap.set('n', '<leader>js', '<cmd>HopChar1<CR>', {
            noremap = true,
            silent = true,
            desc = "Jump to character"
        })
        vim.keymap.set('n', '<leader>jp', '<cmd>HopPattern<CR>', {
            noremap = true,
            silent = true,
            desc = "Jump to pattern"
        })
    end
}}

return M
