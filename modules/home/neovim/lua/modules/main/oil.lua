local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { 
      "nvim-tree/nvim-web-devicons",
      "mrjones2014/legendary.nvim"
    },
    config = function()
      require("oil").setup({
        default_file_explorer = true,
        columns = {
          "icon",
          "size",
          "mtime",
        },
        view_options = {
          show_hidden = true,
          is_hidden_file = function(name)
            return vim.startswith(name, ".")
          end,
        },
        float = {
          border = "rounded",
          max_width = 80,
          max_height = 30,
        },
      })
    end
  }
}

function M.setup()
  local legendary = require("legendary")
  local wk = require("which-key")

  -- Define legendary keymaps format
  local which_key_bindings = {
    {
      "<leader>ee",
      "<cmd>Oil<CR>",
      description = "Open Oil file explorer",
      group = "Explorer"
    },
    {
      "<leader>ef",
      "<cmd>Oil --float<CR>",
      description = "Open Oil in floating window",
      group = "Explorer"
    }
  }

  -- Configure which-key separately
  wk.add({
    { "<leader>e", group = "Explorer" },
    { "<leader>ee", "<cmd>Oil<CR>", desc = "Open Oil file explorer" },
    { "<leader>ef", "<cmd>Oil --float<CR>", desc = "Open Oil in floating window" }
  })

  -- Command Palette Commands
  local command_palette_commands = {
    {
      "Oil",
      description = "Explorer: Open Oil file explorer",
      category = "Explorer"
    },
    {
      "Oil --float",
      description = "Explorer: Open Oil in floating window",
      category = "Explorer"
    }
  }

  -- Register with Legendary
  legendary.keymaps(which_key_bindings)
  legendary.commands(command_palette_commands)
  
  -- Register verification steps
  verify.register_verification("oil", {
    {
      desc = "Oil File Explorer",
      command = ":Oil",
      expected = "Should open Oil file explorer"
    },
    {
      desc = "Oil Floating Window",
      command = ":Oil --float",
      expected = "Should open Oil in a floating window"
    },
    {
      desc = "Legendary Keybindings",
      command = "Which-key <leader>e",
      expected = "Should show Oil explorer group"
    },
    {
      desc = "Command Palette Commands",
      command = ":Legendary commands",
      expected = "Should show Oil commands in Command Palette"
    }
  })
end

return M