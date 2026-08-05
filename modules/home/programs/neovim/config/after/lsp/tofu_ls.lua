local neoconf = require("neoconf")

local base_config = {
  cmd = {
    "tofu-ls",
    "serve",
  },
  filetypes = {
    "opentofu",
    "opentofu-vars",
    "terraform",
  },
  root_markers = {
    ".terraform",
    ".git",
  },
}
return vim.tbl_deep_extend("force", base_config, neoconf.get("tofu_ls") or {})
