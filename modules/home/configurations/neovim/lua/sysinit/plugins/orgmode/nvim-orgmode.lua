local M = {}

M.plugins = {
  {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    config = function()
      require("orgmode").setup({
        win_border = "rounded",
      })
    end,
  },
}

return M
