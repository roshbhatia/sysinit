local M = {}

M.plugins = {
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    config = function()
      require("trouble").setup({})
    end,
    keys = function()
      return {
        {
          "<leader>cl",
          function()
            vim.cmd("Trouble loclist toggle")
          end,
          desc = "Toggle loclist diagnostics",
        },
        {
          "<leader>cq",
          function()
            vim.cmd("Trouble qflist toggle")
          end,
          desc = "Toggle qflist diagnostics",
        },
      }
    end,
  },
}

return M
