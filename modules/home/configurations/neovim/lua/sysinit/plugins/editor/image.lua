local M = {}

M.plugins = {
  {
    "3rd/image.nvim",
    ft = {
      "markdown",
      "org",
    },
    opts = {
      backend = "sixel",
      processor = "magick_rock",
      neorg = {
        filetypes = {
          "org",
        },
      },
    },
  },
}

return M
