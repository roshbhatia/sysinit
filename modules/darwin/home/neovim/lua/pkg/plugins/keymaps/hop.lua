local plugin_family = {}

M.plugins = {{
    'phaazon/hop.nvim',
    branch = 'v2',
    config = function()
        local hop = require('hop')
        local directions = require('hop.hint').HintDirection

        hop.setup({
            keys = 'fjdkslaghrueiwoncmv',
            jump_on_sole_occurrence = true,
            case_sensitive = false
        })

        local map_opts = {
            noremap = true,
            silent = true
        }

        vim.keymap.set('n', '<S-Enter>', '<cmd>HopWord<CR>', map_opts)
        vim.keymap.set('i', '<S-Enter>', '<Esc><cmd>HopWord<CR>', map_opts)
        vim.keymap.set('n', '<leader>j', '<cmd>HopWord<CR>', map_opts)

        vim.keymap.set('n', '<leader>jj', '<cmd>HopWord<CR>', map_opts)
        vim.keymap.set('n', '<leader>jl', '<cmd>HopLine<CR>', map_opts)
        vim.keymap.set('n', '<leader>js', '<cmd>HopChar1<CR>', map_opts)
        vim.keymap.set('n', '<leader>jp', '<cmd>HopPattern<CR>', map_opts)
    end
}}

return plugin_family
