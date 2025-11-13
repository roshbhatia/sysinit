local servers = require("sysinit.plugins.intellicode.lsp.servers")
local diagnostics = require("sysinit.plugins.intellicode.lsp.diagnostics")
local keymaps = require("sysinit.plugins.intellicode.lsp.keymaps")

local M = {}

M.plugins = {
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
      "b0o/SchemaStore.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      servers.setup_configs()
      diagnostics.configure()
      servers.enable_servers()
      vim.lsp.inlay_hint.enable(true)
    end,
    keys = keymaps.get_keymaps(),
  },
}

return M
