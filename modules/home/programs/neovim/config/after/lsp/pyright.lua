local neoconf = require("neoconf")

local base_config = {
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic", -- Can be "off", "basic", or "strict"

        autoImportCompletions = true,

        diagnosticMode = "workspace", -- "openFilesOnly" or "workspace"
        useLibraryCodeForTypes = true,

        inlayHints = {
          variableTypes = true,
          functionReturnTypes = true,
          callArgumentNames = true,
          parameterTypes = true,
        },

        autoSearchPaths = true,
        extraPaths = {},

        diagnosticSeverityOverrides = {
          reportUnusedImport = "information",
          reportUnusedVariable = "information",
          reportDuplicateImport = "warning",
        },
      },
    },
  },
}

return vim.tbl_deep_extend("force", base_config, neoconf.get("pyright") or {})
