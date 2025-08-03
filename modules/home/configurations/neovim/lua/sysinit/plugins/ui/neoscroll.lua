local M = {}

M.plugins = {
  {
    {
      "karb94/neoscroll.nvim",
      lazy = false,
      opts = {
        easing = "sine",
        duration_multiplier = 0.5,
      },
      config = function(_, opts)
        local neoscroll = require("neoscroll")
        neoscroll.setup(opts)

        local keymap = {
          ["<C-y>"] = function()
            neoscroll.scroll(-0.1, { move_cursor = false, duration = 100, easing = "sine" })
          end,
          ["<C-e>"] = function()
            neoscroll.scroll(0.1, { move_cursor = false, duration = 100, easing = "sine" })
          end,
          ["<C-d>"] = function()
            neoscroll.ctrl_d({ duration = 250, easing = "circular" })
          end,
          ["<C-u>"] = function()
            neoscroll.ctrl_u({ duration = 250, easing = "circular" })
          end,
        }

        local modes = { "n", "v", "x" }
        for key, func in pairs(keymap) do
          vim.keymap.set(modes, key, func)
        end
      end,
      keys = function()
        return {
          { "<ScrollWheelUp>", "<C-y>", mode = { "n", "i", "v" } },
          { "<ScrollWheelDown>", "<C-e>", mode = { "n", "i", "v" } },
          { "<C-S-d>", "<CMD>normal! G<CR>" },
          { "<C-S-u>", "<CMD>normal! gg<CR>" },
        }
      end,
    },
  },
}

return M
