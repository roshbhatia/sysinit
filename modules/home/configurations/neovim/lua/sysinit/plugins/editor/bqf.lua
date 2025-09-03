local M = {}

M.plugins = {
  {
    "kevinhwang91/nvim-bqf",
    event = "VeryLazy",
    config = function()
      require("bqf").setup({
        preview = {
          winblend = 0,
        },
      })
    end,
  },
}

return M
