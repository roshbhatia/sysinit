-- Crossplane XPLS language server
return {
  cmd = { "up", "xpls", "serve" },
  filetypes = { "yaml" },
  root_markers = { "crossplane.yaml" },
  single_file_support = false,
}
