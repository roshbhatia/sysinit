local neoconf = require("neoconf")

local base_config = {
  settings = {
    nixd = {
      formatting = {
        command = { "nixfmt" },
      },
      -- Per-project flake expressions can be set via .sysinit/neoconf.json:
      -- "nixd": {
      --   "options": {
      --     "nixos": { "expr": "(builtins.getFlake \"/path\").nixosConfigurations.host.options" },
      --     "home_manager": { "expr": "(builtins.getFlake \"/path\").homeConfigurations.user.options" }
      --   }
      -- }
      options = {},
    },
  },
}

return vim.tbl_deep_extend("force", base_config, neoconf.get("nixd") or {})
