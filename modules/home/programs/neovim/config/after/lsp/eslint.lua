local neoconf = require("neoconf")

local base_config = {
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
  },
  root_markers = {
    "eslint.config.js",
    "eslint.config.cjs",
    "eslint.config.mjs",
    "eslint.config.ts",
    ".eslintrc",
    ".eslintrc.js",
    ".eslintrc.cjs",
    ".eslintrc.json",
    "package.json",
    ".git",
  },
  settings = {
    workingDirectory = { mode = "auto" },
    format = { enable = true },
    validate = "on",
    run = "onType",
  },
}

return vim.tbl_deep_extend("force", base_config, neoconf.get("eslint") or {})
