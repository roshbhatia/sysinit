-- Smart-splits for seamless terminal and window navigation
return {
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    config = function()
      local smart_splits = require('smart-splits')
      
      -- Configure smart-splits
      smart_splits.setup({
        -- Cursor follows moving between splits
        cursor_follows_swapped_bufs = true,
        
        -- Ignore specific filetypes when moving cursor
        ignored_filetypes = {
          'nofile',
          'quickfix',
          'qf',
          'prompt',
        },
        
        -- Ignore floating windows
        ignored_buftypes = { 'nofile', 'terminal' },
        
        -- Enable cross-terminal smart-splits integration
        -- This makes pane navigation work between Neovim and terminal splits
        multiplexer_integration = 'wezterm',
        
        -- Disable default key bindings
        default_amount = 5,
        
        -- How often to check the terminal size while resizing
        resize_mode = {
          quit_key = '<ESC>',
          resize_keys = { 'h', 'j', 'k', 'l' },
          silent = false,
          hooks = {
            on_enter = nil,
            on_leave = nil,
          },
        },
        
        -- Override WezTerm commands
        wezterm_integration = {
          -- Override the default pane movement command in WezTerm
          move_left = "ActivatePaneDirection 'Left'",
          move_right = "ActivatePaneDirection 'Right'",
          move_up = "ActivatePaneDirection 'Up'",
          move_down = "ActivatePaneDirection 'Down'",
          
          -- Override the default pane resize commands in WezTerm
          resize_left = "AdjustPaneSize 'Left' ",
          resize_right = "AdjustPaneSize 'Right' ",
          resize_up = "AdjustPaneSize 'Up' ",
          resize_down = "AdjustPaneSize 'Down' ",
        },
      })
      
      -- Better keybindings
      -- Moving between splits
      vim.keymap.set('n', '<C-h>', smart_splits.move_cursor_left, { desc = "Move to left split" })
      vim.keymap.set('n', '<C-j>', smart_splits.move_cursor_down, { desc = "Move to below split" })
      vim.keymap.set('n', '<C-k>', smart_splits.move_cursor_up, { desc = "Move to above split" })
      vim.keymap.set('n', '<C-l>', smart_splits.move_cursor_right, { desc = "Move to right split" })
      
      -- Resizing splits - Changed from Alt to leader key
      vim.keymap.set('n', '<leader>wh', smart_splits.resize_left, { desc = "Resize split left" })
      vim.keymap.set('n', '<leader>wj', smart_splits.resize_down, { desc = "Resize split down" })
      vim.keymap.set('n', '<leader>wk', smart_splits.resize_up, { desc = "Resize split up" })
      vim.keymap.set('n', '<leader>wl', smart_splits.resize_right, { desc = "Resize split right" })
      
      -- Moving splits around
      vim.keymap.set('n', '<leader>wS', smart_splits.swap_buf_left, { desc = "Swap with left buffer" })
      vim.keymap.set('n', '<leader>wJ', smart_splits.swap_buf_down, { desc = "Swap with bottom buffer" })
      vim.keymap.set('n', '<leader>wK', smart_splits.swap_buf_up, { desc = "Swap with top buffer" })
      vim.keymap.set('n', '<leader>wL', smart_splits.swap_buf_right, { desc = "Swap with right buffer" })
      
      -- Also make it work from terminal mode
      vim.keymap.set('t', '<C-h>', function() vim.cmd("wincmd h") end, { desc = "Move to left split" })
      vim.keymap.set('t', '<C-j>', function() vim.cmd("wincmd j") end, { desc = "Move to below split" })
      vim.keymap.set('t', '<C-k>', function() vim.cmd("wincmd k") end, { desc = "Move to above split" })
      vim.keymap.set('t', '<C-l>', function() vim.cmd("wincmd l") end, { desc = "Move to right split" })
      
      -- Add integration with ZSH highlighting fix for terminal
      local zsh_fix_ok, zsh_fix = pcall(require, "integrations.zsh_highlighting_fix")
      if zsh_fix_ok then
        zsh_fix.setup()
      else
        print("ZSH highlighting fix module not found")
      end
    end,
  }
}
