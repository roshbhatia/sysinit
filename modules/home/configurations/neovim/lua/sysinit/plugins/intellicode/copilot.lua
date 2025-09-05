local M = {}
local config = require("sysinit.config.nvim_config")

M.plugins = {
  {
    enabled = config.is_copilot_enabled(),
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
