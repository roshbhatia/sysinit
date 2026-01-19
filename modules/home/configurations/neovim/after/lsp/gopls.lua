-- gopls (Go language server) configuration overrides
--
-- This file is loaded AFTER nvim-lspconfig defaults and has the highest
-- priority in the LSP config merge order.
--
-- See :help lsp-config-merge for details

return {
  settings = {
    gopls = {
      -- Formatting
      gofumpt = true,

      -- Analysis
      analyses = {
        unusedparams = true,
        unusedwrite = true,
        shadow = true,
        nilness = true,
        unusedvariable = true,
      },

      -- Static analysis
      staticcheck = true,

      -- Hints
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },

      -- Completion
      usePlaceholders = true,
      completeUnimported = true,

      -- Codelens
      codelenses = {
        generate = true,
        gc_details = false,
        test = true,
        tidy = true,
        upgrade_dependency = true,
        regenerate_cgo = true,
      },
    },
  },
}
