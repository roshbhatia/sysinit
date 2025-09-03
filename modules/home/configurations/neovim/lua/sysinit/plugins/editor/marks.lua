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
          desc = "Toggle mark",
        },
        {
          "<leader>mn",
          function()
            require("recall").goto_next()
          end,
          mode = "n",
          noremap = true,
          silent = true,
          desc = "Next mark",
        },
        {
          "<leader>mp",
          function()
            require("recall").goto_prev()
          end,
          mode = "n",
          noremap = true,
          silent = true,
          desc = "Previous mark",
        },
        {
          "<leader>mc",
          function()
            require("recall").clear()
          end,
          mode = "n",
          noremap = true,
          silent = true,
          desc = "Clear all marks",
        },
        {
          "<leader>fm",
          function()
            vim.cmd("Telescope recall")
          end,
          mode = "n",
          noremap = true,
          silent = true,
          desc = "Find marks",
        },
      }
    end,
  },
}

return M
