local M = {}

M.plugins = {
  {
    "3rd/image.nvim",
    ft = {
      "markdown",
      "norg",
      "typst",
    },
    opts = {
      backend = "sixel",
    },
  },
}

return M
