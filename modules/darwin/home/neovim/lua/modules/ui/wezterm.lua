-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/mrjones2014/smart-splits.nvim/refs/heads/master/doc/smart-splits.txt"
local M = {}
M.plugins = {
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false, -- Important to not lazy load for proper multiplexer integration
    config = function()
      local smart_splits = require("smart-splits")
      -- Configure smart-splits
      smart_splits.setup({
        -- Ignore these filetypes when resizing
        ignored_filetypes = { "NvimTree" },
        -- Set multiplexer integration (will auto-detect but you can specify)
        multiplexer_integration = "wezterm",
        -- Default resize amount
        default_amount = 3,
        -- At edge behavior
        at_edge = 'wrap',
        -- move cursor to the other window while moving across windows
        move_cursor_same_row = false,
        -- whether cursor follows buffer when swapping
        cursor_follows_swapped_bufs = true,
        -- resize mode options
        resize_mode = {
          quit_key = '<ESC>',
          resize_keys = { 'h', 'j', 'k', 'l' },
          silent = false,
        },
      })
      
      -- Smart-splits navigation bindings
      vim.keymap.set('n', '<C-h>', function() smart_splits.move_cursor_left() end, {desc = "Move to left split"})
      vim.keymap.set('n', '<C-j>', function() smart_splits.move_cursor_down() end, {desc = "Move to split below"})
      vim.keymap.set('n', '<C-k>', function() smart_splits.move_cursor_up() end, {desc = "Move to split above"})
      vim.keymap.set('n', '<C-l>', function() smart_splits.move_cursor_right() end, {desc = "Move to right split"})
      
      -- Smart-splits resize bindings (using Ctrl+Shift instead of Alt)
      vim.keymap.set('n', '<C-S-h>', function() smart_splits.resize_left() end, {desc = "Resize split left"})
      vim.keymap.set('n', '<C-S-j>', function() smart_splits.resize_down() end, {desc = "Resize split down"})
      vim.keymap.set('n', '<C-S-k>', function() smart_splits.resize_up() end, {desc = "Resize split up"})
      vim.keymap.set('n', '<C-S-l>', function() smart_splits.resize_right() end, {desc = "Resize split right"})
    end
  }
}
return M
