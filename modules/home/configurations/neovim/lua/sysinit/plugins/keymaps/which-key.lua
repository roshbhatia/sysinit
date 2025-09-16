local M = {}
local config = require("sysinit.utils.config")

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
          "<leader>m",
          group = "Marks",
        },
        {
          "<leader>n",
          group = "Notifications",
        },
        {
          "<leader>q",
          group = "Qflist/loclist",
        },
        {
          "<leader>r",
          group = "Refresh",
        },
        {
          "gr",
          group = "LSP",
        },
      })

      wk.add({
        {
          "<leader>h",
          group = "Goose",
        },
        {
          "<leader>y",
          group = "Claude",
        },
        {
          "<leader>u",
          group = "Cursor",
        },
      })

      wk.add({
        {
          "<leader>j",
          group = "OpenCode",
        },
      })

      if config.get().debug then
        wk.add({
          {
            "<leader>p",
            group = "Profiler",
          },
        })
      end
    end,
  },
}

return M
