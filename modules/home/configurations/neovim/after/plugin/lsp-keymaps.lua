vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
    end

    map("<leader>cD", vim.lsp.buf.definition, "Go to definition")
    map("gri", vim.lsp.buf.implementation, "Go to implementation")
    map("grr", vim.lsp.buf.references, "Go to references")
    map("grt", vim.lsp.buf.type_definition, "Go to type definition")

    map("gO", vim.lsp.buf.document_symbol, "Document outline")
    map("<leader>cS", vim.lsp.buf.workspace_symbol, "Workspace symbols")

    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("gra", vim.lsp.buf.code_action, "Code action")
    map("<leader>cA", vim.lsp.codelens.run, "Run codelens action")
    map("grn", vim.lsp.buf.rename, "Rename symbol")

    map("<leader>cn", vim.diagnostic.goto_next, "Next diagnostic")
    map("<leader>cp", vim.diagnostic.goto_prev, "Previous diagnostic")

    map("<leader>cj", function()
      vim.lsp.buf.signature_help({ border = "rounded" })
    end, "Signature help")
  end,
})
