local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    "willothy/wezterm.nvim",
    lazy = false,
    config = true,
    dependencies = { 
      "mrjones2014/legendary.nvim",
      "mrjones2014/smart-splits.nvim"
    }
  }
}

function M.setup()
  local wezterm = require("wezterm")
  local legendary = require("legendary")
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

  -- Which-key bindings
  local which_key_bindings = {
    -- Original WezTerm bindings
    {
      "<leader>w",
      group = "+WezTerm",
      desc = "WezTerm Actions"
    },
    {
      "<leader>wt",
      "<cmd>WeztermSpawn htop<CR>",
      desc = "Spawn htop in WezTerm"
    },
    {
      "<leader>ws",
      "<cmd>WeztermSplitPane<CR>",
      desc = "Create WezTerm Split Pane"
    },
    -- Smart-splits bindings
    {
      "<C-h>",
      function() smart_splits.move_cursor_left() end,
      desc = "Move to left split"
    },
    {
      "<C-j>",
      function() smart_splits.move_cursor_down() end,
      desc = "Move to split below"
    },
    {
      "<C-k>",
      function() smart_splits.move_cursor_up() end,
      desc = "Move to split above"
    },
    {
      "<C-l>",
      function() smart_splits.move_cursor_right() end,
      desc = "Move to right split"
    },
    {
      "<D-S-h>",
      function() smart_splits.resize_left() end,
      desc = "Resize split left"
    },
    {
      "<D-S-j>",
      function() smart_splits.resize_down() end,
      desc = "Resize split down"
    },
    {
      "<D-S-k>",
      function() smart_splits.resize_up() end,
      desc = "Resize split up"
    },
    {
      "<D-S-l>",
      function() smart_splits.resize_right() end,
      desc = "Resize split right"
    }
  }

  -- Command Palette Commands
  local command_palette_commands = {
    {
      "WeztermSpawn",
      description = "WezTerm: Spawn Terminal",
      category = "WezTerm"
    },
    {
      "WeztermSpawn htop",
      description = "WezTerm: Spawn htop",
      category = "WezTerm"
    },
    {
      "WeztermSplitPane",
      description = "WezTerm: Split Pane",
      category = "WezTerm"
    }
  }

  -- Register with Legendary
  legendary.keymaps(which_key_bindings)
  legendary.commands(command_palette_commands)
  
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