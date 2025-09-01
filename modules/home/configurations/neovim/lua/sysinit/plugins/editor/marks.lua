local M = {}

M.plugins = {
  {
    "fnune/recall.nvim",
    version = "*",
    config = function()
      local recall = require("recall")
      recall.setup({})
    end,
    keys = function()
      return {
        {
          "<leader>mm",
          function()
            require("recall").toggle()
          end,
          mode = "n",
          noremap = true,
          silent = true,
          desc = "Mark add/remove",
        },
        {
          "<leader>mn",
          function()
            require("recall").goto_next()
          end,
          mode = "n",
          noremap = true,
          silent = true,
          desc = "Mark next",
        },
        {
          "<leader>mN",
          function()
            require("recall").goto_prev()
          end,
          mode = "n",
          noremap = true,
          silent = true,
          desc = "Mark previous",
        },
        {
          "<leader>mc",
          function()
            require("recall").clear()
          end,
          mode = "n",
          noremap = true,
          silent = true,
          desc = "Mark clear",
        },
        {
          "<leader>fm",
          function()
            vim.cmd("Telescope recall")
          end,
          mode = "n",
          noremap = true,
          silent = true,
          desc = "Mark list",
        },
      }
    end,
  },
}

return M
