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
          separator = " ",
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
          "<leader>?",
          group = "Open command palette",
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
          "<leader>q",
          group = "Loclist",
        },
        {
          "<leader>m",
          group = "Marks",
        },
        {
          "<leader>q",
          group = "Qflist",
        },
        {
          "<leader>r",
          group = "Refresh",
        },
        {
          "<localleader>n",
          group = "Notifications",
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
