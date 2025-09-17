local M = {}
local config = require("sysinit.utils.config")

local deps = {
  "b0o/SchemaStore.nvim",
  "saghen/blink.cmp",
}

if config.is_copilot_enabled() then
  table.insert(deps, "copilotlsp-nvim/copilot-lsp")
end

M.plugins = {
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = deps,
    config = function()
      if config.is_copilot_enabled() then
        vim.g.copilot_nes_debounce = 500
        
        vim.keymap.set("n", "<tab>", function()
          local bufnr = vim.api.nvim_get_current_buf()
          local state = vim.b[bufnr].nes_state
          if state then
            local _ = require("copilot-lsp.nes").walk_cursor_start_edit()
              or (
                require("copilot-lsp.nes").apply_pending_nes()
                and require("copilot-lsp.nes").walk_cursor_end_edit()
              )
            return nil
          else
            return "<C-i>"
          end
        end, { desc = "Accept Copilot NES suggestion", expr = true })
        
        vim.keymap.set("n", "<esc>", function()
          if not require("copilot-lsp.nes").clear() then
          end
        end, { desc = "Clear Copilot suggestion or fallback" })
      end

      local schemastore = require("schemastore")
      local lspconfig = require("lspconfig")

      local builtin_servers = {
        eslint = {},
        gopls = {},
        tflint = {},
        dockerls = {
          cmd = {
            "docker-language-server",
            "start",
            "--stdio",
          },
        },
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

      local custom_servers = {
        up = {
          cmd = {
            "up",
            "xpls",
            "serve",
          },
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

      for server, config in pairs(builtin_servers) do
        config.capabilities = require("blink.cmp").get_lsp_capabilities()
        lspconfig[server].setup(config)
      end

      if config.is_copilot_enabled() then
        local copilot_config = {}
        copilot_config.capabilities = require("blink.cmp").get_lsp_capabilities()
        lspconfig.copilot_ls.setup(copilot_config)
      end

      for server, config in pairs(custom_servers) do
        config.capabilities = require("blink.cmp").get_lsp_capabilities()
        vim.lsp.config(server, config)
        vim.lsp.enable(server)
      end

      vim.diagnostic.config({
        severity_sort = true,
        virtual_text = false,
        virtual_lines = { only_current_line = true },
        update_in_insert = false,
        float = {
          border = "rounded",
          source = "if_many",
        },
        underline = {
          severity = vim.diagnostic.severity.ERROR,
        },
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

      vim.lsp.inlay_hint.enable(true)

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)

          if client and vim.bo[args.buf].filetype == "markdown" then
            if client.server_capabilities then
              client.server_capabilities.documentFormattingProvider = false
              client.server_capabilities.documentRangeFormattingProvider = false
            end
          end

          if client and client:supports_method("textDocument/codeLens") then
            vim.lsp.codelens.refresh()
            vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
              buffer = args.buf,
              callback = vim.lsp.codelens.refresh,
            })
            vim.api.nvim_create_autocmd({ "BufWritePost" }, {
              buffer = args.buf,
              callback = function()
                vim.lsp.codelens.refresh({ bufnr = args.buf })
              end,
            })

            ---@diagnostic disable-next-line: undefined-field
            local timer = (vim.loop and vim.loop.new_timer) and vim.loop.new_timer() or nil
            if timer then
              timer:start(
                250,
                250,
                vim.schedule_wrap(function()
                  if
                    vim.api.nvim_buf_is_valid(args.buf) and vim.api.nvim_buf_is_loaded(args.buf)
                  then
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
        end,
      })
    end,
    keys = function()
      return {
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
    end,
  },
}

return M
