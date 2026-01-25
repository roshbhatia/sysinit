local schemastore = require("schemastore")

return {
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
