-- rust_analyzer (Rust language server) configuration overrides
--
-- This file is loaded AFTER nvim-lspconfig defaults and has the highest
-- priority in the LSP config merge order.
--
-- See :help lsp-config-merge for details

return {
  settings = {
    ["rust-analyzer"] = {
      -- Cargo
      cargo = {
        allFeatures = true,
        loadOutDirsFromCheck = true,
      },

      -- Check on save
      checkOnSave = {
        command = "clippy",
        extraArgs = { "--all", "--", "-W", "clippy::all" },
      },

      -- Completion
      completion = {
        postfix = {
          enable = true,
        },
        autoimport = {
          enable = true,
        },
      },

      -- Inlay hints
      inlayHints = {
        bindingModeHints = {
          enable = true,
        },
        chainingHints = {
          enable = true,
        },
        closingBraceHints = {
          minLines = 10,
        },
        closureReturnTypeHints = {
          enable = "always",
        },
        lifetimeElisionHints = {
          enable = "always",
          useParameterNames = true,
        },
        parameterHints = {
          enable = true,
        },
        typeHints = {
          enable = true,
        },
      },

      -- Proc macro
      procMacro = {
        enable = true,
      },

      -- Diagnostics
      diagnostics = {
        enable = true,
        experimental = {
          enable = true,
        },
      },
    },
  },
}
