local M = {}

M.plugins = {
  {
    "karb94/neoscroll.nvim",
    lazy = false,
    opts = {
      easing = "cubic",
      duration_multiplier = 1.6,
      performance_mode = false,
      mappings = {
        "<C-y>",
        "<C-e>",
        "<C-d>",
        "<C-u>",
      },
    },
    keys = function()
      local neoscroll = require("neoscroll")
      return {
        {
          "<ScrollWheelUp>",
          "<C-y>",
          mode = {
            "n",
            "i",
            "v",
          },
        },
        {
          "<ScrollWheelDown>",
          "<C-e>",
          mode = {
            "n",
            "i",
            "v",
          },
        },
        {
          "<C-S-d>",
          "<CMD>normal! G<CR>",
          mode = {
            "n",
          },
        },
        {
          "<C-S-u>",
          "<CMD>normal! gg<CR>",
          mode = {
            "n",
          },
        },
      }
    end,
  },
}

return M
