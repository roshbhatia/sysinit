local neoconf = require("neoconf")

local base_config = {
  settings = {
    ["rust-analyzer"] = {
      checkOnSave = {
        command = "clippy",
        extraArgs = { "--all-targets", "--all-features" },
      },
      procMacro = {
        enable = true,
      },
      cargo = {
        allFeatures = true,
        loadOutDirsFromCheck = true,
        runBuildScripts = true,
      },
      inlayHints = {
        bindingModeHints = { enable = true },
        chainingHints = { enable = true },
        closingBraceHints = { enable = true },
        closureReturnTypeHints = { enable = "always" },
        lifetimeElisionHints = { enable = "skip_trivial" },
        parameterHints = { enable = true },
        typeHints = { enable = true },
      },
      lens = {
        enable = true,
        implementations = { enable = true },
        references = { enable = true },
        run = { enable = true },
        test = { enable = true },
      },
    },
  },
}

return vim.tbl_deep_extend("force", base_config, neoconf.get("rust_analyzer") or {})
