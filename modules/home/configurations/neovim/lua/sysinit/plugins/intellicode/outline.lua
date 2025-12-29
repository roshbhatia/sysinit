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
        keymaps = {
          show_help = "?",
          close = "q",
          goto_location = "<CR>",
          peek_location = "o",
          goto_and_close = "<S-CR>",
          restore_location = "<C-g>",
          hover_symbol = "K",
          toggle_preview = "P",
          rename_symbol = "grn",
          code_actions = "gra",
          fold = "zc",
          fold_toggle = "za",
          fold_toggle_all = "<S-Tab>",
          unfold = "zo",
          fold_all = "zM",
          unfold_all = "zR",
          fold_reset = "zx",
          down_and_jump = "<localleader>j",
          up_and_jump = "<localleader>k",
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
