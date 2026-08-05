local neoconf = require("neoconf")

local base_config = {
  settings = {
    ["helm-ls"] = {
      yamlls = {
        enabled = true,
        diagnosticsLimit = 50,
        showDiagnosticsDirectly = false,
        path = "yaml-language-server",
      },
      logLevel = "info",
      valuesFiles = {
        mainValuesFile = "values.yaml",
        lintOverlayValuesFile = "values.lint.yaml",
        additionalValuesFilesGlobPattern = "values*.yaml",
      },
    },
  },
}

return vim.tbl_deep_extend("force", base_config, neoconf.get("helm_ls") or {})
