local M = {}
local config = require("sysinit.utils.config")
local util = require("lspconfig.util")

function M.get_builtin_configs()
  local schemastore = require("schemastore")
  local version = vim.version()

  local configs = {
    ast_grep = {
      cmd = { "ast-grep", "lsp" },
      filetypes = {
        "c",
        "cpp",
        "rust",
        "go",
        "java",
        "python",
        "javascript",
        "typescript",
        "html",
        "css",
        "kotlin",
        "dart",
        "lua",
      },
      root_dir = function(fname)
        return util.root_pattern("~/.config/ast-grep/sgconfig.yml")(fname)
      end,
    },
    eslint = {},
    gopls = {},
    tflint = {},
    helm_ls = {},
    jqls = {},
    lua_ls = {},
    nil_ls = {},
    nushell = {},
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
    jsonls = {
      settings = {
        json = {
          schemas = schemastore.json.schemas(),
          validate = { enable = true },
        },
      },
    },
    yamlls = {
      settings = {
        yaml = {
          schemaStore = { enable = false, url = "" },
          schemas = vim.tbl_extend("force", schemastore.yaml.schemas(), {
            Kubernetes = "globPattern",
          }),
        },
      },
    },
  }

  if config.is_copilot_enabled() then
    configs.copilot_ls = {
      on_attach = function(client, bufnr)
        require("sysinit.plugins.intellicode.lsp.copilot").setup(client, bufnr)
      end,
    }
  end

  return configs
end

function M.get_custom_configs()
  return {
    up = {
      cmd = { "up", "xpls", "serve" },
      filetypes = { "yaml" },
      root_dir = require("lspconfig").util.root_pattern("crossplane.yaml"),
    },
  }
end

function M.setup_configs()
  local capabilities = require("blink.cmp").get_lsp_capabilities()

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
