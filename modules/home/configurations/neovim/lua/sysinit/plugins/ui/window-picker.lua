local M = {}

M.plugins = {
  {
    "s1n7ax/nvim-window-picker",
    name = "window-picker",
    lazy = true,
    version = "2.*",
    config = function()
      require("window-picker").setup({
        hint = "floating-big-letter",
      })
    end,
  },
}

return M

