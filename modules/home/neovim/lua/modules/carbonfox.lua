local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    "EdenEast/nightfox.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("nightfox").setup({
        options = {
          styles = {
            comments = "italic",
            keywords = "bold",
            types = "italic,bold",
          },
        },
      })
      vim.cmd("colorscheme carbonfox")
    end
  }
}

function M.setup()
  local legendary = require("legendary")

  -- Command Palette Commands
  local command_palette_commands = {
    {
      description = "Theme: Set Carbonfox",
      command = "<cmd>colorscheme carbonfox<CR>",
      category = "Theme"
    }
  }

  -- Register with Legendary
  legendary.commands(command_palette_commands)

  -- Register verification steps
  verify.register_verification("carbonfox", {
    {
      desc = "Carbonfox Theme",
      command = ":colorscheme",
      expected = "Should show carbonfox as active colorscheme"
    },
    {
      desc = "Command Palette Commands",
      command = ":Legendary commands",
      expected = "Should show Theme commands in Command Palette"
    }
  })
end

return M