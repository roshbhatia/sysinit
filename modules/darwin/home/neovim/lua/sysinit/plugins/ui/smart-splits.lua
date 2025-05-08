-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/mrjones2014/smart-splits.nvim/refs/heads/master/doc/smart-splits.txt"
local M = {}

M.plugins = {{
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    config = function()
        require("smart-splits").setup({
            -- Ignored buffer types (only while resizing)
            ignored_buftypes = {'nofile', 'quickfix', 'prompt'},
            -- Ignored filetypes (only while resizing)
            ignored_filetypes = {'neo-tree'},
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
        vim.keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left, {
            desc = "Move to left split"
        })
        vim.keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down, {
            desc = "Move to bottom split"
        })
        vim.keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up, {
            desc = "Move to top split"
        })
        vim.keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right, {
            desc = "Move to right split"
        })

        -- Keymaps for resizing splits
        vim.keymap.set('n', '<M-h>', require('smart-splits').resize_left, {
            desc = "Decrease width of current split"
        })
        vim.keymap.set('n', '<M-j>', require('smart-splits').resize_down, {
            desc = "Decrease height of current split"
        })
        vim.keymap.set('n', '<M-k>', require('smart-splits').resize_up, {
            desc = "Increase height of current split"
        })
        vim.keymap.set('n', '<M-l>', require('smart-splits').resize_right, {
            desc = "Increase width of current split"
        })

        -- Keymaps for swapping buffers between windows
        vim.keymap.set('n', 'C-H', require('smart-splits').swap_buf_left, {
            desc = "Swap buffer with left window"
        })
        vim.keymap.set('n', 'C-J', require('smart-splits').swap_buf_down, {
            desc = "Swap buffer with window below"
        })
        vim.keymap.set('n', 'C-K', require('smart-splits').swap_buf_up, {
            desc = "Swap buffer with window above"
        })
        vim.keymap.set('n', 'C-L', require('smart-splits').swap_buf_right, {
            desc = "Swap buffer with right window"
        })
    end
}}

return M
