local M = {}
local config = require("sysinit.utils.config")

function M.get_builtin_configs()
  local schemastore = require("schemastore")

  return {
    eslint = {},
    gopls = {},
    tflint = {},
    helm_ls = {},
    jqls = {},
    lua_ls = {},
    nil_ls = {},
    nushell = {},
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
end

function M.get_custom_configs()
  local version = vim.version()

  local configs = {
    up = {
      cmd = { "up", "xpls", "serve" },
      filetypes = { "yaml" },
      root_dir = require("lspconfig").util.root_pattern("crossplane.yaml"),
    },
  }

  if config.is_copilot_enabled() then
    configs.copilot_ls = {
      cmd = {
        "copilot-language-server",
        "--stdio",
      },
      filetypes = { "*" },
      init_options = {
        editorInfo = {
          name = "neovim",
          version = string.format("%d.%d.%d", version.major, version.minor, version.patch),
        },
        editorPluginInfo = {
          name = "Github Copilot LSP for Neovim",
          version = "0.0.1",
        },
      },
      settings = {
        nextEditSuggestions = {
          enabled = true,
        },
      },
      capabilities = {
        textDocument = {
          inlineCompletion = {
            dynamicRegistration = false,
          },
        },
        workspace = {
          didChangeWatchedFiles = {
            dynamicRegistration = false,
          },
        },
      },
      handlers = require("copilot-lsp.handlers"),
      on_attach = function(client, bufnr)
        require("sysinit.plugins.intellicode.lsp.copilot").setup(client, bufnr)
      end,
    }
  end

  return configs
end

function M.setup_configs()
  local capabilities = require("blink.cmp").get_lsp_capabilities()

  for server, cfg in pairs(M.get_builtin_configs()) do
    cfg.capabilities = capabilities
    vim.lsp.config(server, cfg)
  end

  for server, cfg in pairs(M.get_custom_configs()) do
    if server ~= "copilot_ls" then
      cfg.capabilities = capabilities
    end
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