local neoconf = require("neoconf")

local base_config = {
  filetypes = { "terraform", "tf", "terraform-vars" },
  root_markers = {
    ".tflint.hcl",
    ".terraform",
    ".git",
  },
}

return vim.tbl_deep_extend("force", base_config, neoconf.get("tflint") or {})
