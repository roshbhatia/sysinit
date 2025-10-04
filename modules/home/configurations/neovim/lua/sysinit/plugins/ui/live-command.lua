local M = {}

M.plugins = {
  {
    "smjonas/live-command.nvim",
    event = "VeryLazy",
    config = function()
      require("live-command").setup()
    end,
  },
}

return M
