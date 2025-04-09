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

      -- Enable mouse support
      vim.opt.mouse = "a"

      -- Enable system clipboard integration
      if vim.fn.has("unnamedplus") == 1 then
        vim.opt.clipboard = "unnamedplus"
      else
        vim.opt.clipboard = "unnamed"
      end

      -- Configure language servers
      lspconfig.lua_ls.setup({ on_attach = on_attach })
      lspconfig.pyright.setup({ on_attach = on_attach })
      lspconfig.ts_ls.setup({ on_attach = on_attach }) -- Updated tsserver to ts_ls
      lspconfig.gopls.setup({})
      lspconfig.rust_analyzer.setup({})
      lspconfig.terraformls.setup({})
      lspconfig.bashls.setup({})
      lspconfig.dockerls.setup({})
      lspconfig.yamlls.setup({
        settings = {
          yaml = {
            schemas = {
              kubernetes = "/*.yaml",
            },
          },
        },
      })

      -- Custom configuration for nixd (replacement for nixls)
      lspconfig.nixd.setup({
        cmd = { "nixd" },
        filetypes = { "nix" },
        root_dir = lspconfig.util.root_pattern(".git", "*.nix"),
      })
    end,
  },
}
