local verify = require("core.verify")

local M = {}

-- No plugins to define here since lazy.nvim is loaded via Nix

M.plugins = {}

function M.setup()
  -- Lazy.nvim configuration
  require("lazy").setup({
    -- Performance and UI settings
    performance = {
      rtp = {
        disabled_plugins = {
          "gzip",
          "matchit",
          "matchparen",
          "netrwPlugin",
          "tarPlugin",
          "tohtml",
          "tutor",
          "zipPlugin",
        },
      },
    },
    ui = {
      border = "rounded",
      icons = {
        cmd = " ",
        config = " ",
        event = " ",
        ft = " ",
        init = " ",
        keys = " ",
        plugin = " ",
        runtime = " ",
        source = " ",
        start = " ",
        task = " ",
        lazy = "󰒲 ",
      },
    },
    change_detection = {
      notify = false,
    },
  })
  
  local legendary = require("legendary")

  -- Command Palette Commands
  local command_palette_commands = {
    {
      "Lazy",
      description = "Lazy: Show plugin status",
      category = "Lazy"
    },
    {
      "Lazy update",
      description = "Lazy: Update plugins",
      category = "Lazy"
    },
    {
      "Lazy sync",
      description = "Lazy: Sync plugins",
      category = "Lazy"
    },
    {
      "Lazy clean",
      description = "Lazy: Clean plugins",
      category = "Lazy"
    }
  }

  -- Register with Legendary
  legendary.commands(command_palette_commands)

  -- Register verification steps
  verify.register_verification("lazy", {
    {
      desc = "Lazy Plugin Manager",
      command = ":Lazy",
      expected = "Should open Lazy plugin manager UI"
    },
    {
      desc = "Plugin Loading",
      command = "Check if plugins are loaded",
      expected = "All plugins should be loaded without errors"
    }
  })
end

return M