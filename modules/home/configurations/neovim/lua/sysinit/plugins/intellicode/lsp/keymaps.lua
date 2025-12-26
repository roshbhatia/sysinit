local M = {}

function M.get_keymaps()
  return {
    {
      "gra",
      vim.lsp.buf.code_action,
      desc = "Code action",
    },
    {
      "gra",
      vim.lsp.buf.code_action,
      mode = "v",
      desc = "Code action",
    },
    {
      "grn",
      vim.lsp.buf.rename,
      desc = "Rename symbol",
    },
    {
      "gri",
      vim.lsp.buf.implementation,
      desc = "Go to implementation",
    },
    {
      "gO",
      vim.lsp.buf.document_symbol,
      desc = "Document outline",
    },
    {
      "grr",
      vim.lsp.buf.references,
      desc = "Go to references",
    },
    {
      "grt",
      vim.lsp.buf.type_definition,
      desc = "Go to type definition",
    },
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
      "<leader>cS",
      vim.lsp.buf.workspace_symbol,
      desc = "Workspace symbols",
    },
    {
      "<leader>ca",
      vim.lsp.buf.code_action,
      desc = "Code action",
    },
    {
      "<leader>ca",
      vim.lsp.buf.code_action,
      mode = "v",
      desc = "Code action",
    },
    {
      "<leader>cj",
      function()
        vim.lsp.buf.signature_help({ border = "rounded" })
      end,
      desc = "Signature help",
    },
    {
      "<leader>cn",
      vim.diagnostic.goto_next,
      desc = "Next diagnostic",
    },
    {
      "<leader>cp",
      vim.diagnostic.goto_prev,
      desc = "Previous diagnostic",
    },
    {
      "<leader>cr",
      vim.lsp.buf.rename,
      desc = "Rename symbol",
    },
    {
      "<leader>cs",
      vim.lsp.buf.document_symbol,
      desc = "Document symbols",
    },
  }
end

return M
