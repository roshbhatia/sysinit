local M = {}

M.plugins = {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    ft = {
      "markdown",
    },
    config = function()
      require("render-markdown").setup({
        headings = {
          border_virtual = true,
        },
        code = {
          border = "none",
          position = "left",
          language = false,
          highlight = "NONE",
        },
        pipe_table = {
          above = "─",
          below = "─",
          border = {
            "╭",
            "┬",
            "╮",
            "├",
            "┼",
            "┤",
            "╰",
            "┴",
            "╯",
            "│",
            "─",
          },
        },
        completions = {
          blink = {
            enabled = false,
          },
          lsp = {
            enabled = true,
          },
        },
        file_types = {
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
