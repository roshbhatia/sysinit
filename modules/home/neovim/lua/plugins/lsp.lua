return {
  {
    "williamboman/mason.nvim",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "neovim/nvim-lspconfig",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "pyright", "ts_ls" }, -- Updated tsserver to ts_ls
      })

      local lspconfig = require("lspconfig")
      local on_attach = function(_, bufnr)
        local opts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
      end

      -- Configure language servers
      lspconfig.lua_ls.setup({ on_attach = on_attach })
      lspconfig.pyright.setup({ on_attach = on_attach })
      lspconfig.ts_ls.setup({ on_attach = on_attach }) -- Updated tsserver to ts_ls
    end,
  },
}
