local neoconf = require("neoconf")
local schemastore = require("schemastore")

local base_config = {
  settings = {
    json = {
      -- Use schemastore for JSON schemas
      schemas = schemastore.json.schemas(),

      -- Validation
      validate = { enable = true },

      -- Formatting
      format = {
        enable = true,
      },

      -- Keep lines (don't minify)
      keepLines = {
        enable = true,
      },
    },
  },
}

return vim.tbl_deep_extend("force", base_config, neoconf.get("jsonls") or {})
