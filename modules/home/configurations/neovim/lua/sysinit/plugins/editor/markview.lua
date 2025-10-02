local M = {}

M.plugins = {
  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local presets = require("markview.presets")

      require("markview").setup({
        modes = { "n", "no", "c" },
        hybrid_modes = { "n" },

        callbacks = {
          on_enable = function(_, win)
            vim.wo[win].conceallevel = 2
            vim.wo[win].concealcursor = "c"
          end,
        },

        markdown = {
          headings = presets.headings.simple,

          -- Code blocks
          code_blocks = {
            style = "simple",
            position = "left",
            pad_amount = 1,
            language_names = {},
            language_direction = "left",
            min_width = 60,
          },

          tables = presets.tables.rounded,

          horizontal_rules = presets.horizontal_rules.thin,
        },

        filetypes = {
          "markdown",
        },

        sign = {
          enabled = false,
        },
      })
    end,
  },
}

return M
