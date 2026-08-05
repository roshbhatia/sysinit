local neoconf = require("neoconf")

local base_config = {
  settings = {
    ["nil"] = {
      nix = {
        flake = {
          autoArchive = false,
          autoEvalInputs = true,
        },
        evaluation = {
          workers = 4,
        },
        formatting = {
          command = { "alejandra" },
        },
      },
    },
  },
}

return vim.tbl_deep_extend("force", base_config, neoconf.get("nil_ls") or {})
