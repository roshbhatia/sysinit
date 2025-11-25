local M = {}

M.plugins = {
  {
    "nmac427/guess-indent.nvim",
    event = "VeryLazy",
    config = function()
      require("guess-indent").setup({})
    end,
  },
}

return M
