local M = {}
local config = require("sysinit.utils.config")

local deps = {
  "b0o/SchemaStore.nvim",
  "saghen/blink.cmp",
}

if config.is_copilot_enabled() then
  table.insert(deps, "copilotlsp-nvim/copilot-lsp")
end

local function setup_copilot_highlight_groups()
  if not config.is_copilot_enabled() then
    return
  end

  vim.api.nvim_set_hl(0, "CopilotLspNesAdd", {
    fg = "#a6e3a1",
    bg = "#2a2a37",
    bold = true,
    default = true,
  })
  vim.api.nvim_set_hl(0, "CopilotLspNesDelete", {
    fg = "#f38ba8",
    bg = "#3c2a2a",
    strikethrough = true,
    default = true,
  })
  vim.api.nvim_set_hl(0, "CopilotLspNesApply", {
    fg = "#89b4fa",
    bg = "#2a2a3c",
    bold = true,
    default = true,
  })
  vim.api.nvim_set_hl(0, "CopilotNesHint", {
    fg = "#cba6f7",
    bg = "#1e1e2e",
    italic = true,
    default = true,
  })
end

local function setup_copilot_nes()
  if not config.is_copilot_enabled() then
    return
  end

  vim.g.copilot_nes_debounce = 150

  local nes_namespace = vim.api.nvim_create_namespace("copilot_nes_hints")
  local border_namespace = vim.api.nvim_create_namespace("copilot_nes_borders")

  local function update_nes_hints()
    local bufnr = vim.api.nvim_get_current_buf()
    local state = vim.b[bufnr].nes_state

    vim.api.nvim_buf_clear_namespace(bufnr, nes_namespace, 0, -1)
    vim.api.nvim_buf_clear_namespace(bufnr, border_namespace, 0, -1)

    if state then
      local cursor = vim.api.nvim_win_get_cursor(0)
      local row = cursor[1] - 1

      vim.api.nvim_buf_set_extmark(bufnr, border_namespace, row, 0, {
        virt_lines_above = true,
        virt_lines = {
          {
            {
              "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
              "CopilotNesHint",
            },
          },
        },
        priority = 999,
      })

      vim.api.nvim_buf_set_extmark(bufnr, nes_namespace, row, 0, {
        virt_text = {
          { "  ", "CopilotNesHint" },
          { "<leader><tab>", "CopilotLspNesApply" },
          { ": accept", "CopilotNesHint" },
          { " │ ", "CopilotNesHint" },
          { "<leader><esc>", "CopilotLspNesDelete" },
          { ": clear ", "CopilotNesHint" },
          { " ", "CopilotNesHint" },
        },
        virt_text_pos = "eol",
        priority = 1000,
      })

      vim.api.nvim_buf_set_extmark(bufnr, border_namespace, row + 1, 0, {
        virt_lines = {
          {
            {
              "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
              "CopilotNesHint",
            },
          },
        },
        priority = 999,
      })
    end
  end

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter" }, {
    callback = update_nes_hints,
  })

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

          vim.schedule(update_nes_hints)
          return nil
        else
          return "<C-i>"
        end
      end,
      desc = "Accept Copilot NES suggestion",
      expr = true,
    },
    ["<leader><esc>"] = {
      function()
        local success = require("copilot-lsp.nes").clear()
        if success then
          vim.schedule(update_nes_hints)
        end
      end,
      desc = "Clear Copilot NES suggestion",
    },
  }
end

local function get_builtin_servers()
  local schemastore = require("schemastore")

  return {
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
end

local function get_custom_servers()
  local lspconfig = require("lspconfig")
  local version = vim.version()

  local servers = {
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

  if config.is_copilot_enabled() then
    servers.copilot_ls = {
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
      handlers = require("copilot-lsp.handlers"),
      root_dir = vim.uv.cwd(),
      capabilities = {},
    }
  end

  return servers
end

local function setup_servers()
  local builtin_servers = get_builtin_servers()
  local custom_servers = get_custom_servers()
  local lspconfig = require("lspconfig")
  local blink_capabilities = require("blink.cmp").get_lsp_capabilities()

  for server, server_config in pairs(builtin_servers) do
    server_config.capabilities = blink_capabilities
    lspconfig[server].setup(server_config)
  end

  for server, server_config in pairs(custom_servers) do
    if server == "copilot_ls" then
      server_config.capabilities = {}
    else
      server_config.capabilities = blink_capabilities
    end

    vim.lsp.config(server, server_config)
    vim.lsp.enable(server)
  end
end

local function configure_diagnostics()
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
end

local function setup_codelens_timer(args, timer)
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

local function setup_codelens(args, client)
  if not client:supports_method("textDocument/codeLens") then
    return
  end

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
    setup_codelens_timer(args, timer)
  end
end

local function disable_markdown_formatting(args, client)
  if client and vim.bo[args.buf].filetype == "markdown" then
    if client.server_capabilities then
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end
  end
end

local function setup_lsp_attach()
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)

      disable_markdown_formatting(args, client)
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
      setup_copilot_highlight_groups()
      setup_servers()
      configure_diagnostics()
      setup_lsp_attach()

      vim.lsp.inlay_hint.enable(true)
    end,
    keys = function()
      local lsp_keymaps = {
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

      local copilot_keymaps = setup_copilot_nes() or {}

      return vim.tbl_extend("force", lsp_keymaps, copilot_keymaps)
    end,
  },
}

return M
