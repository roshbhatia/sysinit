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
        anti_conceal = {
          above = 5,
          below = 5,
        },
        preset = "obsidian",
        headings = {
          border_virtual = true,
          border_prefix = true,
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
            enabled = true,
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
