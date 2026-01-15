local M = {}

M.plugins = {
  {
    "Bekaboo/dropbar.nvim",
    branch = "master",
    event = "VeryLazy",
    config = function()
      require("dropbar").setup({
        icons = {
          ui = {
            bar = {
              separator = "  ",
              extends = "…",
            },
          },
        },
        menu = {
          scrollbar = {
            enable = false,
          },
        },
      })
    end,
  },
}

return M
