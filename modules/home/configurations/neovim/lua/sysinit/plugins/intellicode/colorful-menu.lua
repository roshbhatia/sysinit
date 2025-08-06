local M = {}

M.plugins = {
  {
    "xzbdmw/colorful-menu.nvim",
    config = function()
      require("colorful-menu").setup({})
    end,
  },
}

return M

