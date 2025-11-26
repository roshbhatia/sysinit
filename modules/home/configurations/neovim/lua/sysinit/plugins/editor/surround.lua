local M = {}

M.plugins = {
  {
    "nvim-mini/mini.surround",
    version = "*",
    event = "VeryLazy",
    opts = {
      mappings = {
        add = ";;", -- Add surrounding in Normal and Visual modes
        delete = ";d", -- Delete surrounding
        find = ";f", -- Find surrounding (to the right)
        find_left = ";F", -- Find surrounding (to the left)
        highlight = ";h", -- Highlight surrounding
        replace = ";r", -- Replace surrounding
      },
    },
  },
}

return M
