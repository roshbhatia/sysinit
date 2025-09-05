local M = {}
local config = require("sysinit.config.nvim_config")

M.plugins = {
  {
    enabled = config.is_copilot_enabled(),
    "giuxtaposition/blink-cmp-copilot",
    dependencies = {
      "zbirenbaum/copilot.lua",
    },
    lazy = true,
  },
}

return M
