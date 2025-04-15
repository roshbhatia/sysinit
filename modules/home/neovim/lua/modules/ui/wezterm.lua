local M = {}

M.plugins = {
  {
    "willothy/wezterm.nvim",
    lazy = false,
    config = false,
    dependencies = {
      "mrjones2014/smart-splits.nvim"
    }
  }
}

function M.setup()
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
  
  -- WezTerm specific commands
  vim.keymap.set('n', '<leader>zt', '<cmd>WeztermSpawn htop<CR>', {desc = "Spawn htop in WezTerm"})
  vim.keymap.set('n', '<leader>zs', '<cmd>WeztermSplitPane<CR>', {desc = "Create WezTerm Split Pane"})
end

return M