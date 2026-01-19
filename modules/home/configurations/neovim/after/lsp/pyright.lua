return {
  settings = {
    python = {
      analysis = {
        -- Type checking mode
        typeCheckingMode = "basic", -- Can be "off", "basic", or "strict"

        -- Auto-import completions
        autoImportCompletions = true,

        -- Diagnostics
        diagnosticMode = "workspace", -- "openFilesOnly" or "workspace"
        useLibraryCodeForTypes = true,

        -- Inlay hints
        inlayHints = {
          variableTypes = true,
          functionReturnTypes = true,
          callArgumentNames = true,
          parameterTypes = true,
        },

        -- Auto-search paths
        autoSearchPaths = true,
        extraPaths = {},

        -- Diagnostics severity overrides
        diagnosticSeverityOverrides = {
          reportUnusedImport = "information",
          reportUnusedVariable = "information",
          reportDuplicateImport = "warning",
        },
      },
    },
  },
}
