-- copilot_ls (GitHub Copilot language server) configuration
--
-- This file is loaded AFTER nvim-lspconfig defaults and has the highest
-- priority in the LSP config merge order.
--
-- See :help lsp-config-merge for details

return {
  on_attach = function(client, bufnr)
    require("sysinit.utils.lsp.copilot").setup(client, bufnr)
  end,
}
