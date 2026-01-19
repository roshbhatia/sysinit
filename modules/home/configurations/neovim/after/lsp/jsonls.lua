-- jsonls (JSON language server) configuration overrides
--
-- This file is loaded AFTER nvim-lspconfig defaults and has the highest
-- priority in the LSP config merge order.
--
-- See :help lsp-config-merge for details

local schemastore = require("schemastore")

return {
  settings = {
    json = {
      -- Use schemastore for JSON schemas
      schemas = schemastore.json.schemas(),

      -- Validation
      validate = { enable = true },

      -- Formatting
      format = {
        enable = true,
      },

      -- Keep lines (don't minify)
      keepLines = {
        enable = true,
      },
    },
  },
}
