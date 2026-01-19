return {
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
          show_symbol_details = false,
        },
        preview_window = {
          live = true,
        },
        guides = {
          markers = {
            bottom = "╰",
          },
        },
        keymaps = {
          rename_symbol = "grn",
          code_actions = "gra",
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
