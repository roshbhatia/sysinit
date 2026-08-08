local neoconf = require("neoconf")
local schemastore = require("schemastore")

local base_config = {
  settings = {
    yaml = {
      schemaStore = { enable = false, url = "" }, -- Disable built-in, use schemastore plugin
      schemas = vim.tbl_extend("force", schemastore.yaml.schemas(), {
        Kubernetes = "globPattern",
      }),

      format = {
        enable = true,
        singleQuote = false,
        bracketSpacing = true,
      },

      validate = true,
      hover = true,
      completion = true,

      customTags = {
        "!reference sequence",
        "!And",
        "!And sequence",
        "!If",
        "!If sequence",
        "!Not",
        "!Not sequence",
        "!Equals",
        "!Equals sequence",
        "!Or",
        "!Or sequence",
        "!FindInMap",
        "!FindInMap sequence",
        "!Base64",
        "!Join",
        "!Join sequence",
        "!Cidr",
        "!Ref",
        "!Sub",
        "!Sub sequence",
        "!GetAtt",
        "!GetAZs",
        "!ImportValue",
        "!ImportValue sequence",
        "!Select",
        "!Select sequence",
        "!Split",
        "!Split sequence",
      },
    },
  },
  handlers = {
    ["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
      if result and type(result.diagnostics) == "userdata" then
        result.diagnostics = {}
      end
      return vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx, config)
    end,
  },
}

return vim.tbl_deep_extend("force", base_config, neoconf.get("yamlls") or {})
