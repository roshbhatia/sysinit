return {
  settings = {
    gopls = {
      -- Formatting
      gofumpt = true,

      -- Analysis
      analyses = {
        unusedparams = true,
        unusedwrite = true,
        shadow = true,
        nilness = true,
        unusedvariable = true,
      },

      -- Static analysis
      staticcheck = true,

      -- Hints
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },

      -- Completion
      usePlaceholders = true,
      completeUnimported = true,

      -- Codelens
      codelenses = {
        generate = true,
        gc_details = false,
        test = true,
        tidy = true,
        upgrade_dependency = true,
        regenerate_cgo = true,
      },
    },
  },
}
