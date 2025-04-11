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

  -- Which-key bindings
  local which_key_bindings = {
    {
      "<leader>e",
      group = "+Explorer",
      desc = "File Explorer Actions"
    },
    {
      "<leader>ee",
      "<cmd>Oil<CR>",
      desc = "Open Oil file explorer"
    },
    {
      "<leader>ef",
      "<cmd>Oil --float<CR>",
      desc = "Open Oil in floating window"
    }
  }

  -- Command Palette Commands
  local command_palette_commands = {
    {
      description = "Explorer: Open Oil file explorer",
      command = "<cmd>Oil<CR>",
      category = "Explorer"
    },
    {
      description = "Explorer: Open Oil in floating window",
      command = "<cmd>Oil --float<CR>",
      category = "Explorer"
    }
  }

  -- Register with Legendary
  legendary.keymaps(which_key_bindings)
  legendary.commands(command_palette_commands)
end

return M