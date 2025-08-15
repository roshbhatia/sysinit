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
          group = "Buffer Actions",
        },
        {
          "<localleader>e",
          group = "Editor Actions",
        },
        {
          "<localleader>r",
          group = "Refresh",
        },
        {
          "<leader>j",
          group = "Goose",
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

      if agents_config.agents.enabled then
        wk.add({
          {
            "<leader>h",
            group = "Copilot - Avante",
          },
          {
            "<leader>j",
            group = "Copilot - OpenCode",
          },
          {
            "<leader>k",
            group = "Copilot - Goose",
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

