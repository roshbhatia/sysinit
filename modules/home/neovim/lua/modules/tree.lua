local M = {}

M.plugins = {
  {
    "ms-jpq/chadtree",
    branch = "chad",
    lazy = false,
    dependencies = { 
      "nvim-tree/nvim-web-devicons",
      "mrjones2014/legendary.nvim"
    },
    build = "python3 -m chadtree deps",
    config = function()
      -- CHADTree doesn't use a Lua setup function like Oil does
      -- Its configuration is handled through vim.g variables
      
      -- Example configuration
      vim.g.chadtree_settings = {
        theme = {
          -- Choose a theme: 'nord', 'solarized', 'trapdoor', 'vim-syntax'
          name = "nord"
        },
        view = {
          width = 30,
          sort_by = {"is_folder", "file_name"},
          show_hidden = true
        },
        keymap = {
          -- You can customize keybindings here if needed
          -- This keeps default bindings
        }
      }
    end
  }
}

function M.setup()
  local legendary = require("legendary")

  -- Which-key bindings using V3 format
  local wk = require("which-key")
  wk.register({
    ["<leader>e"] = { name = "Explorer" },
    ["<leader>ee"] = { "<cmd>CHADopen<CR>", "Open CHADTree explorer" },
    ["<leader>ef"] = { "<cmd>CHADopen --always-focus<CR>", "Open CHADTree (focused)" }
  })

  -- Command Palette Commands
  local command_palette_commands = {
    {
      "CHADopen",
      description = "Explorer: Open CHADTree file explorer",
      category = "Explorer"
    },
    {
      "CHADhelp",
      description = "Explorer: Open CHADTree help",
      category = "Explorer"
    },
    {
      "CHADhelp keybind",
      description = "Explorer: Show CHADTree keybindings",
      category = "Explorer"
    },
    {
      "CHADhelp keybind --web",
      description = "Explorer: Show CHADTree keybindings in browser",
      category = "Explorer"
    },
    {
      "CHADrestore",
      description = "Explorer: Restore window decorations",
      category = "Explorer"
    }
  }

  -- Register with Legendary
  legendary.commands(command_palette_commands)
end

return M