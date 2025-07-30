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
          desc = "Add/Remove",
        },
        {
          "<leader>mn",
          function()
            require("recall").goto_next()
          end,
          mode = "n",
          noremap = true,
          silent = true,
          desc = "Next",
        },
        {
          "<leader>mN",
          function()
            require("recall").goto_prev()
          end,
          mode = "n",
          noremap = true,
          silent = true,
          desc = "Previous",
        },
        {
          "<leader>mc",
          function()
            require("recall").clear()
          end,
          mode = "n",
          noremap = true,
          silent = true,
          desc = "Clear",
        },
        {
          "<leader>fm",
          "<CMD>Telescope recall<CR>",
          mode = "n",
          noremap = true,
          silent = true,
          desc = "Marks",
        },
      }
    end,
  },
}

return M
