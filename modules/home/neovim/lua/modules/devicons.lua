local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    "nvim-tree/nvim-web-devicons",
    lazy = false,
    config = function()
      require("nvim-web-devicons").setup({
        -- Override default icons
        override = {
          -- Example customizations
          default_icon = {
            icon = "",
            color = "#6d8086",
            name = "Default",
          },
          -- Add custom file types if needed
          nix = {
            icon = "",
            color = "#7ebae4",
            name = "Nix",
          },
        },
        -- Global icon settings
        default = true,
        strict = true,
        color_icons = true,
      })
    end
  }
}

function M.setup()
  local legendary = require("legendary")

  -- No user-facing keybindings for this module
  
  -- Command Palette Commands
  local command_palette_commands = {
    {
      description = "DevIcons: Show all icons",
      command = "<cmd>lua print(vim.inspect(require('nvim-web-devicons').get_icons()))<CR>",
      category = "DevIcons"
    }
  }

  -- Register with Legendary
  legendary.commands(command_palette_commands)

  -- Register verification steps
  verify.register_verification("devicons", {
    {
      desc = "DevIcons Loading",
      command = "Check if icons appear in bufferline and other UIs",
      expected = "Should show file type icons in UI components"
    }
  })
end

return M