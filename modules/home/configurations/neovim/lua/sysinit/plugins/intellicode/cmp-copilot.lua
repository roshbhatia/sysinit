local M = {}
local config = require("sysinit.utils.config")

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
