local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    "willothy/wezterm.nvim",
    lazy = false,
    config = true,
    dependencies = {
      "mrjones2014/smart-splits.nvim"
    }
  }
}

function M.setup()
  local wezterm = require("wezterm")
  local commander = require("commander")
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

  -- Register wezterm commands with commander
  commander.add({
    {
      desc = "Spawn htop in WezTerm",
      cmd = "<cmd>WeztermSpawn htop<CR>",
      keys = { "n", "<leader>wt" },
      cat = "WezTerm"
    },
    {
      desc = "Create WezTerm Split Pane",
      cmd = "<cmd>WeztermSplitPane<CR>",
      keys = { "n", "<leader>ws" },
      cat = "WezTerm"
    },
    -- Smart-splits bindings
    {
      desc = "Move to left split",
      cmd = function() smart_splits.move_cursor_left() end,
      keys = { "n", "<C-h>" },
      cat = "Navigation"
    },
    {
      desc = "Move to split below",
      cmd = function() smart_splits.move_cursor_down() end,
      keys = { "n", "<C-j>" },
      cat = "Navigation"
    },
    {
      desc = "Move to split above",
      cmd = function() smart_splits.move_cursor_up() end,
      keys = { "n", "<C-k>" },
      cat = "Navigation"
    },
    {
      desc = "Move to right split",
      cmd = function() smart_splits.move_cursor_right() end,
      keys = { "n", "<C-l>" },
      cat = "Navigation"
    },
    {
      desc = "Resize split left",
      cmd = function() smart_splits.resize_left() end,
      keys = { "n", "<D-S-h>" },
      cat = "Resize"
    },
    {
      desc = "Resize split down",
      cmd = function() smart_splits.resize_down() end,
      keys = { "n", "<D-S-j>" },
      cat = "Resize"
    },
    {
      desc = "Resize split up",
      cmd = function() smart_splits.resize_up() end,
      keys = { "n", "<D-S-k>" },
      cat = "Resize"
    },
    {
      desc = "Resize split right",
      cmd = function() smart_splits.resize_right() end,
      keys = { "n", "<D-S-l>" },
      cat = "Resize"
    }
  })
  
  -- Verify WezTerm integration
  verify.register_verification("wezterm", {
    {
      desc = "WezTerm Terminal Spawn",
      command = ":WeztermSpawn htop",
      expected = "Should open htop in a new WezTerm pane"
    },
    {
      desc = "WezTerm Split Pane",
      command = ":WeztermSplitPane",
      expected = "Should create a new split pane in WezTerm"
    },
    {
      desc = "Smart Splits Navigation",
      command = "<C-h>",
      expected = "Should move to left split or WezTerm pane"
    },
    {
      desc = "Smart Splits Resize",
      command = "<D-S-h>",
      expected = "Should resize current split or WezTerm pane"
    }
  })
end

return M