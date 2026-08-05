local neoconf = require("neoconf")

local base_config = {
  filetypes = { "rego" },
  root_markers = { ".git", "*.rego" },
}

return vim.tbl_deep_extend("force", base_config, neoconf.get("rego_ls") or {})
