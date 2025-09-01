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
    keys = function()
      return {
        {
          "<leader>ss",
          function()
            vim.cmd("'<,'>Sort i")
          end,
          mode = "v",
          desc = "Sort alpha case insensitive",
        },
        {
          "<leader>sS",
          function()
            vim.cmd("'<,'>Sort")
          end,
          mode = "v",
          desc = "Sort alpha case sensitive",
        },
        {
          "<leader>sr",
          function()
            vim.cmd("'<,'>Sort! i")
          end,
          mode = "v",
          desc = "Sort reverse case insensitive",
        },
        {
          "<leader>sR",
          function()
            vim.cmd("'<,'>Sort!")
          end,
          mode = "v",
          desc = "Sort reverse case sensitive",
        },
      }
    end,
  },
}

return M
