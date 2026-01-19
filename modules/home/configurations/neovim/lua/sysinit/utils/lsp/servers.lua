local M = {}

function M.get_builtin_configs()
  -- Base LSP server configurations
  -- Server-specific settings and overrides are in after/lsp/*.lua
  -- which have higher priority in the config merge order.
  --
  -- See :help lsp-config-merge for details

  local configs = {
    copilot_ls = {}, -- Config in after/lsp/copilot_ls.lua
    eslint = {},
    gopls = {}, -- Config in after/lsp/gopls.lua
    tflint = {},
    helm_ls = {},
    jqls = {},
    lua_ls = {}, -- Config in after/lsp/lua_ls.lua
    nil_ls = {}, -- Config in after/lsp/nil_ls.lua
    nixd = {},
    openscad_lsp = {},
    pyright = {}, -- Config in after/lsp/pyright.lua
    terraformls = {},
    rust_analyzer = {}, -- Config in after/lsp/rust_analyzer.lua
    bashls = {},
    marksman = {},
    zls = {},
    awk_ls = {},
    statix = {},
    docker_compose_language_service = {},
    jsonls = {}, -- Config in after/lsp/jsonls.lua
    yamlls = {}, -- Config in after/lsp/yamlls.lua
  }

  return configs
end

function M.get_custom_configs()
  -- Custom LSP servers not in nvim-lspconfig
  -- Server-specific settings and overrides are in after/lsp/*.lua
  --
  -- See :help lsp-config-merge for details

  return {
    up = {}, -- Config in after/lsp/up.lua (Crossplane)
  }
end

function M.setup_configs()
  local capabilities = require("blink.cmp").get_lsp_capabilities()

  require("sysinit.utils.lsp.copilot").suppress_limit_notifications()

  for server, cfg in pairs(M.get_builtin_configs()) do
    cfg.capabilities = capabilities
    vim.lsp.config(server, cfg)
  end

  for server, cfg in pairs(M.get_custom_configs()) do
    cfg.capabilities = capabilities
    vim.lsp.config(server, cfg)
  end
end

function M.enable_servers()
  for server, _ in pairs(M.get_builtin_configs()) do
    vim.lsp.enable(server)
  end

  for server, _ in pairs(M.get_custom_configs()) do
    vim.lsp.enable(server)
  end
end

return M
