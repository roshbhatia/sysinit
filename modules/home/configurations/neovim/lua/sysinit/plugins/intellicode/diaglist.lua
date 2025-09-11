local M = {}

M.plugins = {
  {
    "onsails/diaglist.nvim",
    event = "LSPAttach",
    opts = {},
    keys = function()
      local diaglist = require("diaglist")
      return {
        {
          "<leader>cl",
          diaglist.open_buffer_diagnostics,
          desc = "Loclist diagnostics",
        },
        {
          "<leader>cq",
          diaglist.open_all_diagnostics,
          desc = "Quickfix diagnostics",
        },
      }
    end,
  },
}

return M
