local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { 
      "nvim-tree/nvim-web-devicons"
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
  local commander = require("commander")

  -- Register commands with commander
  commander.add({
    {
      desc = "Open Oil File Explorer",
      cmd = "<cmd>Oil<CR>",
      keys = { "n", "<leader>ee" },
      cat = "Explorer"
    },
    {
      desc = "Open Oil in Floating Window",
      cmd = "<cmd>Oil --float<CR>",
      keys = { "n", "<leader>ef" },
      cat = "Explorer"
    }
  })
  
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
      desc = "Commander Keybindings",
      command = "<leader>ee",
      expected = "Should open Oil explorer"
    },
    {
      desc = "Commander Commands",
      command = ":Telescope commander filter cat=Explorer",
      expected = "Should show Oil commands in Commander palette"
    }
  })
end

return M