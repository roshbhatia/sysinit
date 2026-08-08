local neoconf = require("neoconf")

local base_config = {
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
        path = {
          "?.lua",
          "?/init.lua",
        },
      },

      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          "${3rd}/luv/library",
        },
      },

      diagnostics = {
        globals = { "vim" },
        disable = {
          "missing-fields",
          "incomplete-signature-doc",
        },
      },

      completion = {
        callSnippet = "Replace",
        keywordSnippet = "Replace",
        showWord = "Disable",
      },

      format = {
        enable = false,
      },

      telemetry = {
        enable = false,
      },

      hint = {
        enable = true,
        setType = true,
        paramType = true,
        paramName = "Disable",
        semicolon = "Disable",
        arrayIndex = "Disable",
      },
    },
  },
}

return vim.tbl_deep_extend("force", base_config, neoconf.get("lua_ls") or {})
