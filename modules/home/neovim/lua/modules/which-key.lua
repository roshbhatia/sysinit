local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    "folke/which-key.nvim",
    lazy = false,
    priority = 9999,
    config = function()
      require("which-key").setup({
        win = { 
          border = "rounded",
          width = 0.8,
          height = 0.6,
        },
        icons = {
          breadcrumb = "»",
          separator = "➜",
          group = "+",
        },
        triggers = {
          -- Blacklist specific keys in insert and visual modes
          { mode = "i", keys = "j" },
          { mode = "i", keys = "k" },
          { mode = "v", keys = "j" },
          { mode = "v", keys = "k" },
        }
      })
      
      -- Register which-key prefixes
      local wk = require("which-key")
      wk.register({
        ["<leader>"] = { name = "+Leader" },
        ["g"] = { name = "+Goto" },
        ["["] = { name = "+Prev" },
        ["]"] = { name = "+Next" },
      })
    end
  }
}

function M.setup()
  local legendary = require("legendary")

  -- Command Palette Commands
  local command_palette_commands = {
    {
      "WhichKey",
      description = "Which-key: Show help",
      category = "Which-key"
    }
  }

  -- Register with Legendary
  legendary.commands(command_palette_commands)

  -- Register verification steps
  verify.register_verification("which-key", {
    {
      desc = "Which-key Help",
      command = ":WhichKey",
      expected = "Should show which-key help menu"
    },
    {
      desc = "Leader Key Menu",
      command = "Press <leader>",
      expected = "Should show which-key leader menu"
    }
  })
end

return M