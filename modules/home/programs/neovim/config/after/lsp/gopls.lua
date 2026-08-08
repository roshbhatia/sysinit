local neoconf = require("neoconf")

local base_config = {
  settings = {
    gopls = {
      gofumpt = true,

      analyses = {
        unusedparams = true,
        unusedwrite = true,
        shadow = true,
        nilness = true,
        unusedvariable = true,
      },

      staticcheck = true,

      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },

      usePlaceholders = true,
      completeUnimported = true,

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

return vim.tbl_deep_extend("force", base_config, neoconf.get("gopls") or {})
