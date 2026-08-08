local neoconf = require("neoconf")

local base_config = {
  settings = {
    nixd = {
      formatting = {
        command = { "nixfmt" },
      },
      options = {},
    },
  },
}

return vim.tbl_deep_extend("force", base_config, neoconf.get("nixd") or {})
