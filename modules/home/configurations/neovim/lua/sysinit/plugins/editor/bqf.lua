return {
  {
    "kevinhwang91/nvim-bqf",
    event = "VeryLazy",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("bqf").setup({
        func_map = {
          split = "<localleader>s",
          tabb = "",
          tabc = "",
          vsplit = "<localleader>v",
        },
        preview = {
          winblend = 0,
        },
        show_title = {
          default = false,
        },
        filter = {
          fzf = {
            extra_opts = { "--bind", "ctrl-o:toggle-all", "--delimiter", "│" },
          },
        },
      })
    end,
  },
  {
    "yorickpeterse/nvim-pqf",
    event = "VeryLazy",
    config = function()
      require("pqf").setup({
        signs = {
          error = { text = "", hl = "DiagnosticSignError" },
          warning = { text = "", hl = "DiagnosticSignWarn" },
          info = { text = "", hl = "DiagnosticSignInfo" },
          hint = { text = "", hl = "DiagnosticSignHint" },
        },
        show_multiple_lines = false,
        max_filename_length = 40,
        filename_truncate_prefix = "[…]",
      })
    end,
  },
}
