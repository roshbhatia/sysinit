local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    "willothy/wezterm.nvim",
    lazy = false,
    config = true,
    dependencies = { "mrjones2014/legendary.nvim" }
  }
}

function M.setup()
  local wezterm = require("wezterm")
  local legendary = require("legendary")

  -- Which-key bindings
  local which_key_bindings = {
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
      desc = "Legendary Keybindings",
      command = "Which-key <leader>w",
      expected = "Should show WezTerm action group"
    },
    {
      desc = "Command Palette WezTerm Commands",
      command = ":Legendary commands",
      expected = "Should show WezTerm commands in Command Palette"
    }
  })
end

return M