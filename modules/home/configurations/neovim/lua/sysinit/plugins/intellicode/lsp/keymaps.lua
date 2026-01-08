local M = {}

function M.get_keymaps()
  return {
    -- Navigation: Go to definitions/implementations
    {
      "<leader>cD",
      vim.lsp.buf.definition,
      desc = "Go to definition",
    },
    {
      "gri",
      vim.lsp.buf.implementation,
      desc = "Go to implementation",
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

    -- Symbols and outline
    {
      "gO",
      vim.lsp.buf.document_symbol,
      desc = "Document outline",
    },
    {
      "<leader>cS",
      vim.lsp.buf.workspace_symbol,
      desc = "Workspace symbols",
    },

    -- Code actions and refactoring
    --
    {
      "<leader>ca",
      vim.lsp.buf.code_action,
      mode = "v",
      desc = "Code action",
    },
    {
      "gra",
      vim.lsp.buf.code_action,
      mode = "v",
      desc = "Code action",
    },
    {
      "<leader>cA",
      vim.lsp.codelens.run,
      desc = "Run codelens action",
    },
    {
      "grn",
      vim.lsp.buf.rename,
      desc = "Rename symbol",
    },

    -- Diagnostics
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

    -- Help
    {
      "<leader>cj",
      function()
        vim.lsp.buf.signature_help({ border = "rounded" })
      end,
      desc = "Signature help",
    },
  }
end

return M
