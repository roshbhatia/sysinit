local M = {}

M.plugins = {
  {
    "jake-stewart/auto-cmdheight.nvim",
    lazy = "VeryLazy",
    opts = {
      max_lines = 2,
      duration = 2,
      remove_on_key = true,
      clear_always = true,
    },
  },
}

return M
