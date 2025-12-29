local M = {}

M.plugins = {
  {
    "hedyhli/outline.nvim",
    cmd = {
      "Outline",
    },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("outline").setup({
        outline_items = {
          show_symbol_lineno = true,
        },
        guides = {
          markers = {
            bottom = "╰",
          },
        },

        preview_window = {
          auto_preview = true,
          open_hover_on_preview = true,
          live = true,
        },
        keymaps = {
          rename_symbol = "grn",
          code_actionzas = "gra",
          fold = {},
          fold_toggle = { "<Tab", "za" },
          fold_toggle_all = {},
          unfold = {},
          fold_all = {},
          unfold_all = {},
          fold_reset = "zx",
          down_and_jump = {},
          up_and_jump = {},
        },
      })
    end,
    keys = {
      {
        "<leader>co",
        function()
          vim.cmd("Outline!")
        end,
        desc = "Toggle outline",
      },
    },
  },
}

return M
