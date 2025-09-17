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

  local theme_config =
    json_loader.load_json_file(json_loader.get_config_path("theme_config.json"), "theme_config")
  local colors = theme_config.colors.semantic

  local highlights = {
    CopilotLspNesAdd = { fg = colors.success, bg = "none", bold = true, default = true },
    CopilotLspNesDelete = { fg = colors.error, bg = "none", strikethrough = true, default = true },
    CopilotLspNesApply = { fg = colors.info, bg = "none", bold = true, default = true },
    CopilotNesHint = { fg = colors.warning, bg = "none", italic = true, default = true },
  }

  for name, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

local function get_copilot_keymaps()
  if not config.is_copilot_enabled() then
    return {}
  end

  vim.g.copilot_nes_debounce = 150

  return {
    ["<leader><tab>"] = {
      function()
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
      end,
      desc = "Accept Copilot NES suggestion",
      mode = "n",
      expr = true,
    },
    ["<leader><esc>"] = {
      require("copilot-lsp.nes").clear,
      desc = "Clear Copilot NES suggestion",
      mode = "n",
    },
  }
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
      cmd = { "copilot-language-server", "--stdio" },
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
      settings = { nextEditSuggestions = { enabled = true } },
      handlers = require("copilot-lsp.handlers"),
      root_dir = vim.uv.cwd(),
      capabilities = {},
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
      local lsp_keymaps = {
        { "<leader>cA", vim.lsp.codelens.run, desc = "Run codelens action" },
        { "<leader>cD", vim.lsp.buf.definition, desc = "Go to definition" },
        { "grr", vim.lsp.buf.references, desc = "Go to references" },
        { "<leader>cp", vim.diagnostic.get_prev, desc = "Previous diagnostic" },
        { "<leader>cn", vim.diagnostic.get_next, desc = "Next diagnostic" },
        { "<leader>cr", vim.lsp.buf.rename, desc = "Rename symbol" },
        { "grn", vim.lsp.buf.rename, desc = "Rename symbol" },
        { "<leader>cs", vim.lsp.buf.document_symbol, desc = "Document symbols" },
        {
          "<leader>cj",
          function()
            vim.lsp.buf.signature_help({ border = "rounded" })
          end,
          desc = "Signature help",
        },
        { "<leader>cS", vim.lsp.buf.workspace_symbol, desc = "Workspace symbols" },
        { "gri", vim.lsp.buf.implementation, desc = "Go to implementation" },
        { "grt", vim.lsp.buf.type_definition, desc = "Go to type definition" },
        { "gO", vim.lsp.buf.document_symbol, desc = "Document outline" },
      }

      return vim.tbl_extend("force", lsp_keymaps, get_copilot_keymaps())
    end,
  },
}

return M
