local config = require("sysinit.utils.config")

local M = {}

local deps = {
  "b0o/SchemaStore.nvim",
  "saghen/blink.cmp",
}

if config.is_copilot_enabled() then
  table.insert(deps, "copilotlsp-nvim/copilot-lsp")
end

local function get_builtin_configs()
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

local function get_custom_configs()
  local version = vim.version()

  local configs = {
    up = {
      cmd = { "up", "xpls", "serve" },
      root_markers = { "crossplane.yaml" },
    },
    systemd_lsp = {
      cmd = { "systemd-lsp" },
      filetypes = { "systemd" },
      root_markers = { ".git" },
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
        local au = vim.api.nvim_create_augroup("copilotlsp.init", { clear = true })
        local nes = require("copilot-lsp.nes")
        local debounced_request =
          require("copilot-lsp.util").debounce(nes.request_nes, vim.g.copilot_nes_debounce or 500)

        vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
          callback = function()
            debounced_request(client)
          end,
          group = au,
          buffer = bufnr,
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
          buffer = bufnr,
        })

        local custom_ns = vim.api.nvim_create_namespace("copilotlsp.nes.enhanced")

        local function enhance_nes_display(buf)
          if not vim.api.nvim_buf_is_valid(buf) then
            return
          end

          local state = vim.b[buf].nes_state
          if not state then
            return
          end

          local start_line = state.range.start.line
          local line_text = vim.api.nvim_buf_get_lines(buf, start_line, start_line + 1, false)[1]
            or ""
          local line_length = #line_text

          vim.api.nvim_buf_set_extmark(buf, custom_ns, start_line, line_length, {
            virt_text = {
              { "  ", "Normal" },
              { "gsa", "DiagnosticHint" },
              { ": accept, ", "Comment" },
              { "gsr", "DiagnosticHint" },
              { ": reject", "Comment" },
            },
            virt_text_pos = "eol",
          })
        end

        local function clear_enhanced_display(buf)
          if not vim.api.nvim_buf_is_valid(buf) then
            return
          end
          vim.api.nvim_buf_clear_namespace(buf, custom_ns, 0, -1)
        end

        vim.api.nvim_create_autocmd("BufEnter", {
          callback = function(event)
            local buf = event.buf

            local nes_timer = vim.loop.new_timer()
            local function check_nes_state()
              if not vim.api.nvim_buf_is_valid(buf) then
                if nes_timer then
                  nes_timer:stop()
                  nes_timer:close()
                end
                return
              end

              if vim.b[buf].nes_state and not vim.b[buf].nes_enhanced then
                enhance_nes_display(buf)
                vim.b[buf].nes_enhanced = true
              elseif not vim.b[buf].nes_state and vim.b[buf].nes_enhanced then
                clear_enhanced_display(buf)
                vim.b[buf].nes_enhanced = false
              end
            end

            nes_timer:start(100, 100, vim.schedule_wrap(check_nes_state))

            vim.api.nvim_create_autocmd("BufDelete", {
              buffer = buf,
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
          buffer = bufnr,
        })

        vim.keymap.set({ "n", "i" }, "gsa", function()
          local buf = vim.api.nvim_get_current_buf()
          if vim.b[buf].nes_state then
            local nes_mod = require("copilot-lsp.nes")
            if vim.b[buf].nes_navigated then
              nes_mod.apply_pending_nes(buf)
              vim.api.nvim_buf_clear_namespace(
                buf,
                vim.api.nvim_create_namespace("copilotlsp.nes.enhanced"),
                0,
                -1
              )
              vim.b[buf].nes_navigated = false
              vim.b[buf].nes_enhanced = false
            else
              if nes_mod.walk_cursor_start_edit(buf) then
                vim.b[buf].nes_navigated = true
              end
            end
          end
        end, { desc = "Navigate to/Accept NES suggestion", buffer = bufnr })

        vim.keymap.set({ "n", "i" }, "gsr", function()
          local buf = vim.api.nvim_get_current_buf()
          if vim.b[buf].nes_state then
            local nes_mod = require("copilot-lsp.nes")
            nes_mod.clear()
            vim.api.nvim_buf_clear_namespace(
              buf,
              vim.api.nvim_create_namespace("copilotlsp.nes.enhanced"),
              0,
              -1
            )
            vim.b[buf].nes_navigated = false
            vim.b[buf].nes_enhanced = false
          end
        end, { desc = "Reject NES", buffer = bufnr })
      end,
    }
  end

  return configs
end

local function setup_configs()
  local capabilities = require("blink.cmp").get_lsp_capabilities()

  for server, cfg in pairs(get_builtin_configs()) do
    cfg.capabilities = capabilities
    vim.lsp.config(server, cfg)
  end

  for server, cfg in pairs(get_custom_configs()) do
    if server ~= "copilot_ls" then
      cfg.capabilities = capabilities
    end
    vim.lsp.config(server, cfg)
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

local function enable_servers()
  for server, _ in pairs(get_builtin_configs()) do
    vim.lsp.enable(server)
  end

  for server, _ in pairs(get_custom_configs()) do
    vim.lsp.enable(server)
  end
end

M.plugins = {
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = deps,
    config = function()
      setup_configs()
      configure_diagnostics()
      setup_lsp_attach()
      enable_servers()
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

      return keys
    end,
  },
}

return M
