local config = require("sysinit.utils.config")
local json_loader = require("sysinit.pkg.utils.json_loader")

local M = {}

local deps = {
  "b0o/SchemaStore.nvim",
  "saghen/blink.cmp",
}

if config.is_copilot_enabled() then
  table.insert(deps, "copilotlsp-nvim/copilot-lsp")
end

local function setup_copilot_highlights()
  if not config.is_copilot_enabled() then
    return
  end

  vim.g.copilot_nes_enable = true
  vim.g.copilot_nes_virtual_text = true

  local theme_config =
    json_loader.load_json_file(json_loader.get_config_path("theme_config.json"), "theme_config")
  local colors = theme_config.colors.semantic

  local highlights = {
    CopilotLspNesAdd = {
      fg = colors.success,
      bg = "none",
      bold = true,
      default = true,
    },
    CopilotLspNesDelete = {
      fg = colors.error,
      bg = "none",
      strikethrough = true,
      default = true,
    },
    CopilotLspNesApply = {
      fg = colors.info,
      bg = "none",
      bold = true,
      default = true,
    },
    CopilotLspNesHint = {
      fg = colors.warning,
      bg = "none",
      italic = true,
      default = true,
    },
    CopilotLspNesVirtualText = {
      fg = colors.comment,
      bg = "none",
      italic = true,
      default = true,
    },
    CopilotLspNesHeader = {
      fg = colors.accent,
      bg = "none",
      bold = true,
      italic = true,
      default = true,
    },
  }

  for name, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

local function get_builtin_servers()
  local schemastore = require("schemastore")

  return {
    eslint = {},
    gopls = {},
    tflint = {},
    dockerls = { cmd = { "docker-language-server", "start", "--stdio" } },
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

local function get_custom_servers()
  local lspconfig = require("lspconfig")
  local version = vim.version()

  local servers = {
    up = {
      cmd = { "up", "xpls", "serve" },
      root_dir = function()
        local fd = vim.fn.system("fd crossplane.yaml")
        return fd ~= "" and vim.fn.fnamemodify(fd, ":p:h") or vim.fn.getcwd()
      end,
    },
    systemd_lsp = {
      cmd = { "systemd-lsp" },
      filetypes = { "systemd" },
      root_dir = lspconfig.util.root_pattern(".git"),
      single_file_support = true,
    },
  }

  if config.is_copilot_enabled() then
    servers.copilot_ls = {
      name = "copilot_ls",
      cmd = {
        "copilot-language-server",
        "--stdio",
      },
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
      root_dir = vim.uv.cwd(),
      on_init = function(client)
        local au = vim.api.nvim_create_augroup("copilotlsp.init", { clear = true })
        local nes = require("copilot-lsp.nes")
        local debounced_request =
          require("copilot-lsp.util").debounce(nes.request_nes, vim.g.copilot_nes_debounce or 500)

        vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
          callback = function()
            debounced_request(client)
          end,
          group = au,
        })

        vim.api.nvim_create_autocmd("BufEnter", {
          callback = function()
            local td_params = vim.lsp.util.make_text_document_params()
            client:notify("textDocument/didFocus", {
              textDocument = {
                uri = td_params.uri,
              },
            })
          end,
          group = au,
        })

        local custom_ns = vim.api.nvim_create_namespace("copilotlsp.nes.enhanced")

        local function enhance_nes_display(bufnr)
          if not vim.api.nvim_buf_is_valid(bufnr) then
            return
          end

          local state = vim.b[bufnr].nes_state
          if not state then
            return
          end

          local start_line = state.range.start.line
          local header_text = "<C-CR>:  , <C-BS>: "

          local header_line = math.max(0, start_line - 1)

          vim.api.nvim_buf_set_extmark(bufnr, custom_ns, header_line, 0, {
            virt_lines = {
              {
                {
                  header_text,
                  "CopilotLspNesHeader",
                },
              },
            },
            virt_lines_above = true,
          })
        end

        local function clear_enhanced_display(bufnr)
          if not vim.api.nvim_buf_is_valid(bufnr) then
            return
          end
          vim.api.nvim_buf_clear_namespace(bufnr, custom_ns, 0, -1)
        end

        vim.api.nvim_create_autocmd("BufEnter", {
          callback = function(event)
            local bufnr = event.buf

            local nes_timer = vim.loop.new_timer()
            local function check_nes_state()
              if not vim.api.nvim_buf_is_valid(bufnr) then
                if nes_timer then
                  nes_timer:stop()
                  nes_timer:close()
                end
                return
              end

              if vim.b[bufnr].nes_state and not vim.b[bufnr].nes_enhanced then
                enhance_nes_display(bufnr)
                vim.b[bufnr].nes_enhanced = true
              elseif not vim.b[bufnr].nes_state and vim.b[bufnr].nes_enhanced then
                clear_enhanced_display(bufnr)
                vim.b[bufnr].nes_enhanced = false
              end
            end

            nes_timer:start(100, 100, vim.schedule_wrap(check_nes_state))

            vim.api.nvim_create_autocmd("BufDelete", {
              buffer = bufnr,
              callback = function()
                if nes_timer then
                  nes_timer:stop()
                  nes_timer:close()
                end
              end,
              once = true,
            })
          end,
          group = au,
        })
      end,
    }
  end

  return servers
end

local function setup_servers()
  local lspconfig = require("lspconfig")
  local capabilities = require("blink.cmp").get_lsp_capabilities()

  for server, config in pairs(get_builtin_servers()) do
    config.capabilities = capabilities
    lspconfig[server].setup(config)
  end

  for server, config in pairs(get_custom_servers()) do
    config.capabilities = server == "copilot_ls" and {} or capabilities
    vim.lsp.config(server, config)
    vim.lsp.enable(server)
  end
end

local function configure_diagnostics()
  vim.diagnostic.config({
    severity_sort = true,
    virtual_text = false,
    virtual_lines = { only_current_line = true },
    update_in_insert = false,
    float = { border = "rounded", source = "if_many" },
    underline = { severity = vim.diagnostic.severity.ERROR },
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "",
        [vim.diagnostic.severity.HINT] = "",
        [vim.diagnostic.severity.INFO] = "",
        [vim.diagnostic.severity.WARN] = "",
      },
      numhl = {
        [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
        [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
        [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
        [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
      },
    },
  })
end

local function setup_codelens(args, client)
  if not client:supports_method("textDocument/codeLens") then
    return
  end

  vim.lsp.codelens.refresh()

  vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
    buffer = args.buf,
    callback = vim.lsp.codelens.refresh,
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    buffer = args.buf,
    callback = function()
      vim.lsp.codelens.refresh({ bufnr = args.buf })
    end,
  })

  local timer = (vim.loop and vim.loop.new_timer) and vim.loop.new_timer() or nil
  if timer then
    timer:start(
      250,
      250,
      vim.schedule_wrap(function()
        if vim.api.nvim_buf_is_valid(args.buf) and vim.api.nvim_buf_is_loaded(args.buf) then
          vim.lsp.codelens.refresh({ bufnr = args.buf })
        else
          timer:stop()
          timer:close()
        end
      end)
    )

    vim.api.nvim_buf_attach(args.buf, false, {
      on_detach = function()
        timer:stop()
        timer:close()
      end,
    })
  end
end

local function setup_lsp_attach()
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)

      if client and vim.bo[args.buf].filetype == "markdown" and client.server_capabilities then
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
      end

      setup_codelens(args, client)
    end,
  })
end

M.plugins = {
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = deps,
    config = function()
      setup_copilot_highlights()
      setup_servers()
      configure_diagnostics()
      setup_lsp_attach()
      vim.lsp.inlay_hint.enable(true)
    end,
    keys = function()
      local keys = {
        {
          "<leader>cA",
          vim.lsp.codelens.run,
          desc = "Run codelens action",
        },
        {
          "<leader>cD",
          vim.lsp.buf.definition,
          desc = "Go to definition",
        },
        {
          "grr",
          vim.lsp.buf.references,
          desc = "Go to references",
        },
        {
          "<leader>cp",
          vim.diagnostic.get_prev,
          desc = "Previous diagnostic",
        },
        {
          "<leader>cn",
          vim.diagnostic.get_next,
          desc = "Next diagnostic",
        },
        {
          "<leader>cr",
          vim.lsp.buf.rename,
          desc = "Rename symbol",
        },
        {
          "grn",
          vim.lsp.buf.rename,
          desc = "Rename symbol",
        },
        {
          "<leader>cs",
          vim.lsp.buf.document_symbol,
          desc = "Document symbols",
        },
        {

          "<leader>cj",
          function()
            vim.lsp.buf.signature_help({ border = "rounded" })
          end,
          desc = "Signature help",
        },
        {
          "<leader>cS",
          vim.lsp.buf.workspace_symbol,
          desc = "Workspace symbols",
        },
        {
          "gri",
          vim.lsp.buf.implementation,
          desc = "Go to implementation",
        },
        {
          "grt",
          vim.lsp.buf.type_definition,
          desc = "Go to type definition",
        },
        {
          "gO",
          vim.lsp.buf.document_symbol,
          desc = "Document outline",
        },
      }

      if config.is_copilot_enabled() then
        table.insert(keys, {
          "<C-CR>",
          function()
            local bufnr = vim.api.nvim_get_current_buf()
            if vim.b[bufnr].nes_state then
              local nes = require("copilot-lsp.nes")
              if vim.b[bufnr].nes_navigated then
                nes.apply_pending_nes(bufnr)
                vim.api.nvim_buf_clear_namespace(
                  bufnr,
                  vim.api.nvim_create_namespace("copilotlsp.nes.enhanced"),
                  0,
                  -1
                )
                vim.b[bufnr].nes_navigated = false
                vim.b[bufnr].nes_enhanced = false
              else
                if nes.walk_cursor_start_edit(bufnr) then
                  vim.b[bufnr].nes_navigated = true
                end
              end
            end
          end,
          mode = { "n", "i" },
          desc = "Navigate to/Accept NES suggestion",
          buffer = true,
        })

        table.insert(keys, {
          "<C-BS>",
          function()
            local bufnr = vim.api.nvim_get_current_buf()
            if vim.b[bufnr].nes_state then
              local nes = require("copilot-lsp.nes")
              nes.clear()
              vim.api.nvim_buf_clear_namespace(
                bufnr,
                vim.api.nvim_create_namespace("copilotlsp.nes.enhanced"),
                0,
                -1
              )
              vim.b[bufnr].nes_navigated = false
              vim.b[bufnr].nes_enhanced = false
              return "<C-BS>"
            else
              return "<C-BS>"
            end
          end,
          mode = { "n", "i" },
          expr = true,
          desc = "Reject NES",
          buffer = true,
        })
      end

      return keys
    end,
  },
}

return M
