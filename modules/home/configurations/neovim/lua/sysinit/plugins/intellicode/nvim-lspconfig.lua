local config = require("sysinit.utils.config")
local servers = require("sysinit.plugins.intellicode.lsp.servers")
local diagnostics = require("sysinit.plugins.intellicode.lsp.diagnostics")
local attach = require("sysinit.plugins.intellicode.lsp.attach")
local keymaps = require("sysinit.plugins.intellicode.lsp.keymaps")
local copilot_commands = require("sysinit.plugins.intellicode.lsp.copilot-commands")

local M = {}

local deps = {
  "b0o/SchemaStore.nvim",
  "saghen/blink.cmp",
}

if config.is_copilot_enabled() then
  table.insert(deps, "copilotlsp-nvim/copilot-lsp")
end

M.plugins = {
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = deps,
    config = function()
      servers.setup_configs()
      diagnostics.configure()
      attach.setup()
      servers.enable_servers()
      vim.lsp.inlay_hint.enable(true)

      -- Setup Copilot commands
      if config.is_copilot_enabled() then
        copilot_commands.setup_commands()
      end
    end,
    keys = keymaps.get_keymaps(),
  },
}

return M
