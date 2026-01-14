local servers = require("sysinit.utils.lsp.servers")
local diagnostics = require("sysinit.utils.lsp.diagnostics")
local keymaps = require("sysinit.utils.lsp.keymaps")

local M = {}

M.plugins = {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    priority = 900,
    dependencies = {
      "b0o/SchemaStore.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      servers.setup_configs()
      diagnostics.configure()
      servers.enable_servers()
    end,
    keys = keymaps.get_keymaps(),
  },
}

return M
