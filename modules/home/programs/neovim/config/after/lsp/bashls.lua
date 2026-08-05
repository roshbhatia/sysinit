local neoconf = require("neoconf")

local base_config = {
  filetypes = { "bash", "sh", "zsh" },
  root_markers = { ".git" },
  settings = {
    bashIde = {
      includeAllWorkspaceSymbols = true,
    },
  },
}

return vim.tbl_deep_extend("force", base_config, neoconf.get("bashls") or {})
