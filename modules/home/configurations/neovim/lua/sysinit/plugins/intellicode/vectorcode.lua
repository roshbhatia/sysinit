local M = {}
local config = require("sysinit.utils.config")

M.plugins = {
  {
    "Davidyz/VectorCode",
    enabled = config.is_codecompanion_enabled(),
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
}

return M
