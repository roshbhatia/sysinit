local M = {}

M.plugins = {
  {
    "jake-stewart/auto-cmdheight.nvim",
    event = "VeryLazy",
    opts = {
      max_lines = 1,
      duration = 2,
      remove_on_key = true,
      clear_always = true,
    },
  },
}

return M
