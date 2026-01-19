-- lua_ls (Lua language server) configuration overrides
--
-- This file is loaded AFTER nvim-lspconfig defaults and has the highest
-- priority in the LSP config merge order.
--
-- See :help lsp-config-merge for details

return {
  settings = {
    Lua = {
      -- Runtime
      runtime = {
        version = "LuaJIT",
        path = {
          "?.lua",
          "?/init.lua",
        },
      },

      -- Workspace
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          "${3rd}/luv/library",
        },
      },

      -- Diagnostics
      diagnostics = {
        globals = { "vim" },
        disable = {
          "missing-fields",
          "incomplete-signature-doc",
        },
      },

      -- Completion
      completion = {
        callSnippet = "Replace",
        keywordSnippet = "Replace",
        showWord = "Disable",
      },

      -- Formatting (disable in favor of stylua)
      format = {
        enable = false,
      },

      -- Telemetry
      telemetry = {
        enable = false,
      },

      -- Hints
      hint = {
        enable = true,
        setType = true,
        paramType = true,
        paramName = "Disable",
        semicolon = "Disable",
        arrayIndex = "Disable",
      },
    },
  },
}
