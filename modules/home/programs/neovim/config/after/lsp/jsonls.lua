local neoconf = require("neoconf")
local schemastore = require("schemastore")

local base_config = {
  settings = {
    json = {
      schemas = schemastore.json.schemas(),

      validate = { enable = true },

      format = {
        enable = true,
      },

      keepLines = {
        enable = true,
      },
    },
  },
}

return vim.tbl_deep_extend("force", base_config, neoconf.get("jsonls") or {})
