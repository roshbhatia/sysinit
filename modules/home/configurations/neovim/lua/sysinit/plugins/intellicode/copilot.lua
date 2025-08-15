local agents_config = require("sysinit.config.agents_config").load_config()
local M = {}

M.plugins = {
  {
    enabled = agents_config.agents.enabled and agents_config.agents.copilot.enabled,
    "zbirenbaum/copilot.lua",
    lazy = false,
    config = function()
      require("copilot").setup({
        panel = {
          auto_refresh = false,
        },
        suggestion = {
          enabled = false,
          auto_trigger = false,
        },
      })
    end,
  },
}

return M
