local M = {}

M.plugins = {
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("treesitter-context").setup({
        mutliwindow = true,
        separator = "",
        multiline_threshold = 5,
      })

      vim.cmd("TSContext enable")
    end,
  },
}

return M

