local capabilities = require("blink.cmp").get_lsp_capabilities()

local builtin_configs = {
  copilot_ls = {},
  eslint = {},
  gopls = {},
  tflint = {},
  helm_ls = {},
  jqls = {},
  lua_ls = {},
  nil_ls = {},
  nixd = {},
  openscad_lsp = {},
  pyright = {},
  terraformls = {},
  rust_analyzer = {},
  bashls = {},
  marksman = {},
  zls = {},
  awk_ls = {},
  statix = {},
  docker_compose_language_service = {},
  jsonls = {},
  yamlls = {},
}

local custom_configs = {
  up = {},
}

for server, cfg in pairs(builtin_configs) do
  cfg.capabilities = capabilities
  vim.lsp.config(server, cfg)
end

for server, cfg in pairs(custom_configs) do
  cfg.capabilities = capabilities
  vim.lsp.config(server, cfg)
end

for server in pairs(builtin_configs) do
  vim.lsp.enable(server)
end

for server in pairs(custom_configs) do
  vim.lsp.enable(server)
end
