-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/mrjones2014/smart-splits.nvim/refs/heads/master/doc/smart-splits.txt"
local M = {}

M.plugins = {{
    "mrjones2014/smart-splits.nvim",
    lazy = false, -- recommended not to lazy load when using terminal multiplexer integration
    config = function()
        require("smart-splits").setup({
            -- Ignored buffer types (only while resizing)
            ignored_buftypes = {'nofile', 'quickfix', 'prompt'},
            -- Ignored filetypes (only while resizing)
            ignored_filetypes = {'NvimTree', 'neo-tree'},
            -- Default resize amount
            default_amount = 3,
            -- Behavior when cursor is at edge
            at_edge = 'wrap',
            -- Multiplexer integration (automatically determined unless explicitly set)
            -- Set to "wezterm" to force WezTerm integration
            multiplexer_integration = "wezterm",
            -- Whether cursor follows swapped buffers
            cursor_follows_swapped_bufs = true,
            -- Configure resize mode
            resize_mode = {
                -- Key to exit resize mode
                quit_key = '<ESC>',
                -- Keys for resize directions (h,j,k,l)
                resize_keys = {'h', 'j', 'k', 'l'},
                -- Don't show resize mode notifications
                silent = false
            },
            -- Log level
            log_level = 'info'
        })

        -- Keymaps for moving between splits
        vim.keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left)
        vim.keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down)
        vim.keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up)
        vim.keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right)

        -- Keymaps for resizing splits
        vim.keymap.set('n', '<M-h>', require('smart-splits').resize_left)
        vim.keymap.set('n', '<M-j>', require('smart-splits').resize_down)
        vim.keymap.set('n', '<M-k>', require('smart-splits').resize_up)
        vim.keymap.set('n', '<M-l>', require('smart-splits').resize_right)

        -- Keymaps for swapping buffers between windows
        vim.keymap.set('n', '<leader><leader>h', require('smart-splits').swap_buf_left)
        vim.keymap.set('n', '<leader><leader>j', require('smart-splits').swap_buf_down)
        vim.keymap.set('n', '<leader><leader>k', require('smart-splits').swap_buf_up)
        vim.keymap.set('n', '<leader><leader>l', require('smart-splits').swap_buf_right)
    end
}}

return M
