local neoconf = require("neoconf")

local base_config = {
  filetypes = {
    "graphql",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
  },
  root_markers = {
    ".graphqlrc",
    ".graphqlrc.json",
    ".graphqlrc.yaml",
    ".graphqlrc.yml",
    ".graphqlrc.js",
    ".graphqlrc.ts",
    "graphql.config.js",
    "graphql.config.cjs",
    "graphql.config.mjs",
    "graphql.config.ts",
  },
}

return vim.tbl_deep_extend("force", base_config, neoconf.get("graphql") or {})
