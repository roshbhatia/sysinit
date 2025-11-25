local M = {}

M.plugins = {
  {
    "Bekaboo/dropbar.nvim",
    branch = "master",
    event = "BufReadPost",
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },
    config = function()
      require("dropbar").setup({
        icons = {
          ui = {
            bar = {
              separator = "  ",
              extends = "…",
            },
          },
        },
        menu = {
          scrollbar = {
            enable = false,
          },
        },
        bar = {
          pick = {
            pivots = "fjdkslaghrueiwoncmv",
          },
        },
      })
    end,
    keys = function()
      local dropbar_api = require("dropbar.api")
      return {
        {
          "<leader>fx",
          dropbar_api.pick,
          mode = "n",
          desc = "Pick from winbar symbols",
        },
      }
    end,
  },
}

return M
