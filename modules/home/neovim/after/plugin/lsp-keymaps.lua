vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf

    -- Custom leader keymaps (not provided by Neovim 0.12 defaults)
    -- Neovim defaults: gri, grr, grt, gO, gra, grn, K, CTRL-S (insert)
    Snacks.keymap.set("n", "<leader>cD", vim.lsp.buf.definition, { buffer = bufnr, desc = "Go to definition" })
    Snacks.keymap.set("n", "<leader>cS", vim.lsp.buf.workspace_symbol, { buffer = bufnr, desc = "Workspace symbols" })

    Snacks.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code action" })
    Snacks.keymap.set("n", "<leader>cA", vim.lsp.codelens.run, { buffer = bufnr, desc = "Run codelens action" })

    Snacks.keymap.set("n", "<leader>cn", vim.diagnostic.goto_next, { buffer = bufnr, desc = "Next diagnostic" })
    Snacks.keymap.set("n", "<leader>cp", vim.diagnostic.goto_prev, { buffer = bufnr, desc = "Previous diagnostic" })

    Snacks.keymap.set("n", "<leader>cj", function()
      vim.lsp.buf.signature_help({ border = "rounded" })
    end, { buffer = bufnr, desc = "Signature help" })
  end,
})
