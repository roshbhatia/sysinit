-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/folke/which-key.nvim/refs/heads/main/doc/which-key.nvim.txt"
local M = {}

M.plugins = {
  {
    "folke/which-key.nvim",
    lazy = false,
    dependencies = { "echasnovski/mini.icons" },
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
        -- use automatic trigger detection
        triggers = { { "<auto>", mode = "nxsotc" } },
      })
      
      vim.keymap.set("n", "<leader>W", function()
        require("which-key").show({
          keys = "<c-w>",
          mode = "n", 
          loop = true -- Keep popup open until <esc>
        })
      end, { desc = "Window Hydra Mode" })
    end
  }
}

return M