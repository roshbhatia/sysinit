local agents_config = require("sysinit.config.agents_config").load_config()
local M = {}

M.plugins = {
  {
    enabled = agents_config.agents.enabled and agents_config.agents.copilot.enabled,
    "giuxtaposition/blink-cmp-copilot",
    dependencies = {
      "zbirenbaum/copilot.lua",
    },
    lazy = true,
  },
}

return M
