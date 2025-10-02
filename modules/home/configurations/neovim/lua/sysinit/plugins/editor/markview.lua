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
        preview = {
          -- Modes where preview is shown
          modes = { "n", "no", "c" },
          -- Modes where hybrid mode is active
          hybrid_modes = { "n" },

          -- Icon provider: "internal", "mini", or "devicons"
          icon_provider = "devicons",

          callbacks = {
            on_enable = function(_, win)
              vim.wo[win].conceallevel = 2
              vim.wo[win].concealcursor = "c"
            end,
          },

          -- Filetypes to attach to
          filetypes = {
            "markdown",
          },
        },

        markdown = {
          -- Use simple preset for headings (similar to obsidian style)
          headings = presets.headings.simple,

          -- Code blocks configuration
          code_blocks = {
            style = "simple",
            position = "left",
            pad_amount = 1,
            language_names = {},
            language_direction = "left",
            min_width = 60,
          },

          -- Use rounded borders for tables (default)
          tables = presets.tables.rounded,

          -- Simple thin horizontal rules
          horizontal_rules = presets.horizontal_rules.thin,
        },

        -- Disable sign column icons
        sign = {
          enabled = false,
        },
      })
    end,
  },
}

return M
