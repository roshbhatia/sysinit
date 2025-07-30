local M = {}

M.plugins = {
  {
    "stevearc/aerial.nvim",
    cmd = {
      "AerialToggle",
    },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("aerial").setup({
        highlight_on_hover = true,
        layout = {
          width = 40,
          resize_to_content = false,
        },
        filter_kind = false,
        autojump = true,
        manage_folds = true,
        link_folds_to_tree = true,
        lsp = {
          diagnostics_trigger_update = true,
        },
        backends = {
          "lsp",
          "treesitter",
          "markdown",
          "asciidoc",
          "man",
        },
      })
    end,
    keys = {
      {
        "<leader>co",
        "<CMD>AerialToggle!<CR>",
        desc = "Toggle outline",
      },
    },
  },
}

return M
