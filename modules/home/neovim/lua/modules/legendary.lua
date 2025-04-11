local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    "mrjones2014/legendary.nvim",
    lazy = false,
    priority = 10000,
    dependencies = { 
      "folke/which-key.nvim",
      "nvim-tree/nvim-web-devicons"
    },
    config = function()
      require("legendary").setup({
        -- Keymaps will be added by individual modules
        keymaps = {},
        
        -- Command palette configuration
        commands = {},
        
        -- Autocmds can be added here if needed
        autocmds = {},
        
        -- UI Configuration
        ui = {
          border = "rounded",
          width = 0.6,
          height = 0.6,
          
          -- Sorting and filtering
          filter_mode = "fuzzy",
          sort_modifier = ":alpha",
          
          -- Repeat last action
          repeat_last_action = true,
          
          -- Reduce UI clutter
          reduce_ui_clutter = true,
        },
        
        -- Extensions
        extensions = {
          which_key = {
            auto_register = true
          }
        },
        
        -- Misc settings
        select_prompt = "> ",
        log_level = vim.log.levels.INFO,
      })
    end
  }
}

function M.setup()
  local legendary = require("legendary")
  
  -- Basic keymaps
  local which_key_bindings = {
    {
      "<leader>l",
      group = "+Legendary",
      desc = "Legendary Actions"
    },
    {
      "<leader>lf",
      "<cmd>Legendary<CR>",
      desc = "Open Legendary finder"
    },
    {
      "<leader>lk",
      "<cmd>Legendary keymaps<CR>",
      desc = "Show all keymaps"
    },
    {
      "<leader>lc",
      "<cmd>Legendary commands<CR>",
      desc = "Show all commands"
    }
  }
  
  -- Command Palette Commands
  local command_palette_commands = {
    {
      description = "Legendary: Open finder",
      command = "<cmd>Legendary<CR>",
      category = "Legendary"
    },
    {
      description = "Legendary: Show keymaps",
      command = "<cmd>Legendary keymaps<CR>",
      category = "Legendary"
    },
    {
      description = "Legendary: Show commands",
      command = "<cmd>Legendary commands<CR>",
      category = "Legendary"
    }
  }
  
  -- Register with Legendary
  legendary.keymaps(which_key_bindings)
  legendary.commands(command_palette_commands)
  
  -- Register verification steps
  verify.register_verification("legendary", {
    {
      desc = "Legendary Finder",
      command = ":Legendary",
      expected = "Should open Legendary command palette"
    },
    {
      desc = "Legendary Keymaps",
      command = ":Legendary keymaps",
      expected = "Should show all registered keymaps"
    },
    {
      desc = "Legendary Which-key Integration",
      command = "Press <leader>",
      expected = "Should show which-key menu"
    }
  })
end

return M