-- up (Crossplane LSP) configuration
--
-- This is a custom LSP server for Crossplane YAML files.
-- It provides IDE features for Crossplane compositions and XRDs.
--
-- This file is loaded AFTER nvim-lspconfig defaults and has the highest
-- priority in the LSP config merge order.
--
-- See :help lsp-config-merge for details

return {
  cmd = { "up", "xpls", "serve" },
  filetypes = { "yaml" },
  root_dir = require("lspconfig").util.root_pattern("crossplane.yaml"),
  single_file_support = false,
}
