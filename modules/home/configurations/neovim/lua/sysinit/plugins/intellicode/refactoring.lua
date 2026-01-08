local M = {}

M.plugins = {
  {
    "ThePrimeagen/refactoring.nvim",
    event = "LSPAttach",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {},
  },
}

return M
