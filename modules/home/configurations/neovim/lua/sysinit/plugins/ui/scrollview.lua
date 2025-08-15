local M = {}

M.plugins = {
  {
    "dstein64/nvim-scrollview",
    event = "VeryLazy",
    config = function()
      require("scrollview").setup({
        signs_on_startup = {},
      })
    end,
  },
}

return M
