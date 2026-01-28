local schemastore = require("schemastore")

return {
  settings = {
    yaml = {
      -- Use schemastore for JSON schemas
      schemaStore = { enable = false, url = "" }, -- Disable built-in, use schemastore plugin
      schemas = vim.tbl_extend("force", schemastore.yaml.schemas(), {
        -- Custom Kubernetes schema pattern
        Kubernetes = "globPattern",
      }),

      -- Formatting
      format = {
        enable = true,
        singleQuote = false,
        bracketSpacing = true,
      },

      -- Validation
      validate = true,
      hover = true,
      completion = true,

      -- Custom tags for GitLab CI, CloudFormation, etc.
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
      -- Fix: some servers send diagnostics = {} (object) instead of [] (array)
      -- Neovim decodes empty JSON object as vim.empty_dict() userdata, causing crash
      if result and type(result.diagnostics) == "userdata" then
        result.diagnostics = {}
      end
      return vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx, config)
    end,
  },
}
