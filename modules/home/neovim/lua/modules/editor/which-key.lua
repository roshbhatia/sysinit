-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/folke/which-key.nvim/refs/heads/main/doc/which-key.nvim.txt"
local M = {}

M.plugins = {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    config = function()
      local wk = require("which-key")
      
      wk.setup({
        plugins = {
          marks = true,
          registers = true,
          spelling = {
            enabled = true,
            suggestions = 20,
          },
          presets = {
            operators = true,
            motions = true,
            text_objects = true,
            windows = true,
            nav = true,
            z = true,
            g = true,
          },
        },
        win = {
          border = "rounded",
          padding = { 2, 2, 2, 2 },
        },
        layout = {
          spacing = 3,
        },
        icons = {
          breadcrumb = "»",
          separator = "➜",
          group = "+",
        },
        show_help = true,
        show_keys = true,
        triggers = {
          { "<auto>", mode = "nxsotc" },
        },
      })
      
      wk.add({
        { "<leader>f", group = "Files" },
        { "<leader>b", group = "Buffers" },
        { "<leader>s", group = "Search" },
        { "<leader>g", group = "Git" },
        { "<leader>l", group = "LSP" },
      })
    end
  }
}

return M