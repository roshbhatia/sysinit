local M = {}

M.plugins = {
  {
    "tris203/precognition.nvim",
    opts = {
      startVisible = false,
      disabled_fts = {
        "alpha",
      },
    },
    event = "VeryLazy",
    keys = function()
      local function toggle_precognition()
        local state = require("precognition").toggle()
        if state then
          vim.notify("Precognition ON", vim.log.levels.INFO)
        else
          vim.notify("Precognition OFF", vim.log.levels.INFO)
        end
      end
      return {
        {
          "<localleader>P",
          toggle_precognition,
          desc = "Toggle Precognition",
        },
      }
    end,
  },
}

return M
