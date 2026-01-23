vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

local servers = {
  "awk_ls",
  "bashls",
  "contextive",
  "copilot_ls",
  "docker_compose_language_service",
  "eslint",
  "gopls",
  "helm_ls",
  "jqls",
  "jsonls",
  "lsp_ai",
  "lua_ls",
  "marksman",
  "nil_ls",
  "nixd",
  "openscad_lsp",
  "pyright",
  "rust_analyzer",
  "statix",
  "terraformls",
  "tflint",
  "up",
  "yamlls",
  "zls",
}

vim.lsp.enable(servers)
