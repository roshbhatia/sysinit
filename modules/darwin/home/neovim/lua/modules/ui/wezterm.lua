-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/mrjones2014/smart-splits.nvim/refs/heads/master/doc/smart-splits.txt"
local M = {}

M.plugins = {
  {
    "willothy/wezterm.nvim",
    lazy = false,
    dependencies = {
      "mrjones2014/smart-splits.nvim"
    },
    config = function()
      local smart_splits = require("smart-splits")

      -- Configure smart-splits
      smart_splits.setup({
        -- Ignore these filetypes when resizing
        ignored_filetypes = { "NvimTree" },
        -- Multiplexer integration
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

      require("wezterm").setup({})

      -- Smart-splits navigation bindings
      vim.keymap.set('n', '<C-h>', function() smart_splits.move_cursor_left() end, {desc = "Move to left split"})
      vim.keymap.set('n', '<C-j>', function() smart_splits.move_cursor_down() end, {desc = "Move to split below"})
      vim.keymap.set('n', '<C-k>', function() smart_splits.move_cursor_up() end, {desc = "Move to split above"})
      vim.keymap.set('n', '<C-l>', function() smart_splits.move_cursor_right() end, {desc = "Move to right split"})
      
      -- Smart-splits resize bindings
      vim.keymap.set('n', '<A-h>', function() smart_splits.resize_left() end, {desc = "Resize split left"})
      vim.keymap.set('n', '<A-j>', function() smart_splits.resize_down() end, {desc = "Resize split down"})
      vim.keymap.set('n', '<A-k>', function() smart_splits.resize_up() end, {desc = "Resize split up"})
      vim.keymap.set('n', '<A-l>', function() smart_splits.resize_right() end, {desc = "Resize split right"})
      
      -- Register with which-key
      local wk = require("which-key")
      wk.add({
        { "<leader>w", group = "Window", icon = { icon = "󰖮", hl = "WhichKeyIconCyan" } },
        { "<leader>wt", "<cmd>WeztermSpawn<CR>", desc = "Spawn Terminal", mode = "n" },
        { "<leader>ws", "<cmd>WeztermSplitPane<CR>", desc = "Split Pane", mode = "n" },
        { "<leader>wv", "<cmd>WeztermSplitPane --right<CR>", desc = "Vertical Split", mode = "n" },
        { "<leader>wh", "<cmd>WeztermSplitPane --bottom<CR>", desc = "Horizontal Split", mode = "n" },
        { "<leader>wz", "<cmd>WeztermZoom<CR>", desc = "Zoom Pane", mode = "n" },
        
        -- Smart splits operations
        { "<leader>wr", group = "Resize", mode = "n" },
        { "<leader>wrl", function() smart_splits.resize_left(5) end, desc = "Resize Left", mode = "n" },
        { "<leader>wrj", function() smart_splits.resize_down(5) end, desc = "Resize Down", mode = "n" },
        { "<leader>wrk", function() smart_splits.resize_up(5) end, desc = "Resize Up", mode = "n" },
        { "<leader>wrh", function() smart_splits.resize_right(5) end, desc = "Resize Right", mode = "n" },
        
        -- Navigation shortcuts for Control keys
        { "<C-h>", function() smart_splits.move_cursor_left() end, desc = "Move Left", mode = "n" },
        { "<C-j>", function() smart_splits.move_cursor_down() end, desc = "Move Down", mode = "n" },
        { "<C-k>", function() smart_splits.move_cursor_up() end, desc = "Move Up", mode = "n" },
        { "<C-l>", function() smart_splits.move_cursor_right() end, desc = "Move Right", mode = "n" },
      })
    end
  }
}

return M