-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/stevearc/oil.nvim/refs/heads/master/doc/api.md"
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
      
      -- Setup key bindings for oil navigation
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
      
      -- Register with which-key
      local wk = require("which-key")
      wk.add({
        { "<leader>o", group = "Oil", icon = { icon = "󰏘", hl = "WhichKeyIconBlue" } },
        { "<leader>oo", "<cmd>Oil<CR>", desc = "Open Oil Explorer", mode = "n" },
        { "<leader>of", "<cmd>Oil --float<CR>", desc = "Open Oil in Float", mode = "n" },
        { "<leader>oh", function() 
            require("oil").open(vim.fn.expand("~")) 
          end, 
          desc = "Open Home Directory"
        },
      })
    end
  }
}

return M