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
        { "<leader>a", group = "AI" },
        { "<leader>b", group = "Buffer" },
        { "<leader>c", group = "Code" },
        { "<leader>d", group = "Debugger" },
        { "<leader>e", group = "Editor" },
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git" },
        { "<leader>h", group = "Claude" },
        { "<leader>i", group = "Cursor" },
        { "<leader>j", group = "OpenCode" },
        { "<leader>k", group = "Goose" },
        { "<leader>m", group = "Marks" },
        { "<leader>n", group = "Notifications" },
        { "<leader>q", group = "Qflist/Loclist" },
        { "<leader>r", group = "Refresh" },
        { "<leader>u", group = "Copilot" },
        { "<localleader>m", group = "Markdown", ft = "markdown" },
        { "ga", group = "Copilot" },
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
