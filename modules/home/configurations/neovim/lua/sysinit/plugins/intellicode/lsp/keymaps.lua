local M = {}

function M.get_keymaps()
  return {
    {
      "<leader>cA",
      vim.lsp.codelens.run,
      desc = "Run codelens action",
    },
    {
      "<leader>cD",
      vim.lsp.buf.definition,
      desc = "Go to definition",
    },
    {
      "grr",
      vim.lsp.buf.references,
      desc = "Go to references",
    },
    {
      "<leader>cp",
      vim.diagnostic.get_prev,
      desc = "Previous diagnostic",
    },
    {
      "<leader>cn",
      vim.diagnostic.get_next,
      desc = "Next diagnostic",
    },
    {
      "<leader>cr",
      vim.lsp.buf.rename,
      desc = "Rename symbol",
    },
    {
      "grn",
      vim.lsp.buf.rename,
      desc = "Rename symbol",
    },
    {
      "<leader>cs",
      vim.lsp.buf.document_symbol,
      desc = "Document symbols",
    },
    {
      "<leader>cj",
      function()
        vim.lsp.buf.signature_help({ border = "rounded" })
      end,
      desc = "Signature help",
    },
    {
      "<leader>cS",
      vim.lsp.buf.workspace_symbol,
      desc = "Workspace symbols",
    },
    {
      "gri",
      vim.lsp.buf.implementation,
      desc = "Go to implementation",
    },
    {
      "grt",
      vim.lsp.buf.type_definition,
      desc = "Go to type definition",
    },
    {
      "gO",
      vim.lsp.buf.document_symbol,
      desc = "Document outline",
    },
  }
end

return M
