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
  local commander = require("commander")

  -- Register devicons commands with commander
  commander.add({
    {
      desc = "Show All DevIcons",
      cmd = function()
        local icons = require('nvim-web-devicons').get_icons()
        vim.api.nvim_echo({{vim.inspect(icons), "Normal"}}, true, {})
      end,
      cat = "DevIcons"
    }
  })

  -- Register verification steps
  verify.register_verification("devicons", {
    {
      desc = "DevIcons Loading",
      command = "Check if icons appear in bufferline and other UIs",
      expected = "Should show file type icons in UI components"
    },
    {
      desc = "Commander Commands",
      command = ":Telescope commander filter cat=DevIcons",
      expected = "Should show DevIcons commands in Commander palette"
    }
  })
end

return M