return {
  cmd = { "up", "xpls", "serve" },
  filetypes = { "yaml" },
  root_dir = require("lspconfig").util.root_pattern("crossplane.yaml"),
  single_file_support = false,
}
