local M = {}

M.plugins = {
  {
    "pta2002/intellitab.nvim",
    event = "InsertEnter",
    keys = function()
      return {
        {
          "<Tab>",
          function()
            require("intellitab").indent()
          end,
          mode = "i",
          silent = true,
          desc = "Intellitab smart",
        },
      }
    end,
  },
}

return M
