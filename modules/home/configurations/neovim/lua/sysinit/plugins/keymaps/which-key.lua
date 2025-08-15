local nvim_config = require("sysinit.config.nvim_config").load_config()
local M = {}

M.plugins = {
  {
    "folke/which-key.nvim",
    lazy = false,
    config = function()
      local wk = require("which-key")

      wk.setup({
        preset = "helix",
        icons = {
          mappings = false,
          separator = "➜",
        },
        notify = false,
        win = {
          border = "rounded",
          wo = {
            winblend = 0,
          },
        },
        layout = {
          spacing = 6,
          align = "center",
        },
      })
      wk.add({
        {
          "<localleader>b",
          group = "Buffer Actions",
        },
        {
          "<localleader>e",
          group = "Editor Actions",
        },
        {
          "<localleader>P",
          group = "Precognition",
        },
        {
          "<localleader>r",
          group = "Refresh",
        },
        {
          "<leader>j",
          group = "AI Terminals",
        },
        {
          "<leader>b",
          group = "Buffer",
        },
        {
          "<leader>c",
          group = "Code",
        },
        {
          "<localleader>d",
          group = "Debugger",
        },
        {
          "<leader>e",
          group = "Editor",
        },
        {
          "<leader>f",
          group = "Find",
        },
        {
          "<localleader>g",
          group = "Git",
        },
        {
          "<localleader>gb",
          group = "Git Buffer/Blame",
        },
        {
          "<localleader>gh",
          group = "Hunk",
        },
        {
          "<localleader>.",
          group = "Cursor",
        },
        {
          "<leader>m",
          group = "Marks",
        },
        {
          "<localleader>n",
          group = "Notifications",
        },
        {
          "<leader>t",
          group = "Terminal",
        },
        {
          "<leader>?",
          group = "Commands",
        },
      })

      wk.add({
        {
          "<leader>jg",
          group = "Goose",
        },
        {
          "<leader>jc",
          group = "Claude",
        },
        {
          "<leader>jo",
          group = "OpenCode",
        },
        {
          "<leader>jd",
          group = "Diagnostics",
        },
        {
          "<leader>ja",
          group = "Add Files",
        },
        {
          "<leader>jA",
          group = "Add All Buffers",
        },
        {
          "<leader>je",
          group = "Explain",
        },
        {
          "<leader>jv",
          group = "Review",
        },
        {
          "<localleader>g",
          group = "Add to Goose (Telescope)",
        },
        {
          "<localleader>c",
          group = "Add to Claude (Telescope)",
        },
        {
          "<localleader>o",
          group = "Add to OpenCode (Telescope)",
        },
      })

      if vim.env.SYSINIT_DEBUG == "1" then
        wk.add({
          {
            "<localleader>p",
            group = "Profiler",
          },
        })
      end
    end,
  },
}

return M
