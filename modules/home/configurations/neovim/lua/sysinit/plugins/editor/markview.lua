local M = {}

M.plugins = {
  {
    "OXY2DEV/markview.nvim",
    ft = "markdown",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("markview").setup({
        preview = {
          enable = false,
        },
      })
    end,
    keys = function()
      return {
        {
          "<localleader>mp",
          "<cmd>Markview splitOpen<cr>",
          desc = "Open Editor Split Preview",
          ft = "markdown",
        },
      }
    end,
  },
}

return M
