local agents_config = require("sysinit.config.agents_config").load_config()
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
          group = "Buffer",
        },
        {
          "<localleader>e",
          group = "Editor",
        },
        {
          "<localleader>r",
          group = "Refresh",
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
          "<leader>d",
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
          "<leader>g",
          group = "Git",
        },
        {
          "<leader>gb",
          group = "Buffer",
        },
        {
          "<leader>gh",
          group = "Hunk",
        },
        {
          "<leader>gd",
          group = "Diff",
        },
        {
          "<leader>gt",
          group = "Toggle",
        },
        {
          "<leader>gq",
          group = "Quickfix",
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
          "<leader>?",
          group = "Commands",
        },
      })

      if agents_config.agents.enabled then
        wk.add({
          {
            "<leader>j",
            group = "Agent",
          },
        })
      end

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
