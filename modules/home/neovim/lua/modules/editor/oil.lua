-- sysinit.nvim.readme-url="https://raw.githubusercontent.com/stevearc/oil.nvim/master/README.md"

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

return M