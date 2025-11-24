local M = {}

M.plugins = {
  {
    "A7Lavinraj/fyler.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    branch = "stable",
    event = "VeryLazy",
    opts = {
      integrations = {
        icon = "nvim_web_devicons",
      },
      views = {
        finder = {
          indentscope = {
            enabled = false,
          },
        },
      },
    },
    keys = function()
      local fyler = require("fyler")
      return {
        {
          "<leader>et",
          function()
            fyler.toggle({ kind = "split_left_most" })
          end,
          desc = "Toggle explore in filesystem buffer as tree",
        },
      }
    end,
  },
}

return M
