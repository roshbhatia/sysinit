local M = {}

M.plugins = {
  {
    "sQVe/sort.nvim",
    cmd = "Sort",
    config = function()
      require("sort").setup({
        delimiters = {
          ",",
          "|",
          ";",
          ":",
          "s",
          "t",
          "\n",
        },
      })
    end,
  },
}

return M
