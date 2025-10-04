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
        { "<leader>?", group = "Open command palette" },
        { "<leader>b", group = "Buffer" },
        { "<leader>c", group = "Code" },
        { "<leader>d", group = "Debugger" },
        { "<leader>e", group = "Editor" },
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git" },
        { "<leader>m", group = "Marks" },
        { "<leader>n", group = "Notifications" },
        { "<leader>q", group = "Qflist/Loclist" },
        { "<leader>r", group = "Refresh" },
        { "<localleader>m", group = "Markdown", ft = "markdown" },
        { "ga", group = "Copilot" },
        { "gr", group = "LSP" },
      })

      if config.is_agents_enabled() then
        wk.add({
          { "<leader>a", group = "AI" },
          { "<leader>k", group = "Goose" },
          { "<leader>l", group = "OpenCode" },
          { "<leader>u", group = "Copilot" },
          { "<leader>j", group = "Cursor" },
          { "<leader>h", group = "Claude" },
        })
      end

      if config.get().debug then
        wk.add({
          { "<leader>p", group = "Profiler" },
        })
      end
    end,
  },
}

return M
