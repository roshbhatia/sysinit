local M = {}
local config = require("sysinit.utils.config")

M.plugins = {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
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
        { "<leader>?", group = "Open command palette" },
        { "<leader>b", group = "Buffer" },
        { "<leader>c", group = "Code" },
        { "<leader>ce", group = "Code: Execute/Debug" },
        { "<leader>d", group = "Diff" },
        { "<leader>e", group = "Editor" },
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git" },
        { "<leader>gb", group = "Git: Buffer" },
        { "<leader>gh", group = "Git: Hunk" },
        { "<leader>gr", group = "Git: Review" },
        { "<leader>j", group = "AI Agents" },
        { "<leader>m", group = "Marks" },
        { "<leader>n", group = "Notifications" },
        { "<leader>o", group = "Org" },
        { "<leader>q", group = "Qflist/Loclist" },
        { "<leader>r", group = "Refresh" },
        { "<localleader>m", group = "Markdown", ft = "markdown" },
        { "gr", group = "LSP" },
      })

      if config.get().debug then
        wk.add({
          { "<leader>p", group = "Profiler" },
        })
      end
    end,
  },
}

return M
