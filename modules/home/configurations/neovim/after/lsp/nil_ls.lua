-- nil_ls (Nix language server) configuration overrides
--
-- This file is loaded AFTER nvim-lspconfig defaults and has the highest
-- priority in the LSP config merge order.
--
-- See :help lsp-config-merge for details

return {
  settings = {
    ["nil"] = {
      nix = {
        -- Flake support
        flake = {
          autoArchive = false, -- Don't automatically archive flake inputs
          autoEvalInputs = true,
        },

        -- Binary cache
        binary = {
          evaluation = {
            workers = 4,
          },
        },

        -- Formatting
        formatting = {
          command = { "alejandra" }, -- Use alejandra formatter
        },
      },
    },
  },
}
