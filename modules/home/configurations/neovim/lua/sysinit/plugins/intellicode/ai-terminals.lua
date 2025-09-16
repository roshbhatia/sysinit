local M = {}
local config = require("sysinit.utils.config")

M.plugins = {
  {
    "aweis89/ai-terminals.nvim",
    enabled = config.is_agents_enabled(),
    dependencies = {
      "folke/snacks.nvim",
    },
    opts = {
      auto_terminal_keymaps = {
        env = {
          PAGER = "bat",
        },
        prefix = "<leader>h",
        terminals = {
          { name = "claude", key = "j" },
          { name = "opencode", key = "h" },
          { name = "cursor", key = "y" },
          { name = "goose", key = "u" },
        },
        enable_diffing = true,
      },
    },
  },
}

return M
