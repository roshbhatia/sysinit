vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

local servers = {
  "ast_grep",
  "awk_ls",
  "bashls",
  "contextive",
  "copilot_ls",
  "cue",
  "dockerls",
  "docker_compose_language_service",
  "eslint",
  "gopls",
  "graphql",
  "helm_ls",
  "jqls",
  "jsonls",
  "lsp_ai",
  "lua_ls",
  "marksman",
  "nil_ls",
  "nixd",
  "pyright",
  "ruff",
  "rego_ls",
  "rust_analyzer",
  "statix",
  "terraformls",
  "tflint",
  "up",
  "yamlls",
}

vim.lsp.enable(servers)

-- diffview:// and fugitive:// buffers carry a real filetype, so a server starts
-- and is then asked about a path that is not on disk. nixd answers every inlay
-- hint on one with "-32602: clangd only supports 'file' URI scheme".
local function on_disk(buf)
  if vim.api.nvim_buf_get_name(buf) == "" then
    return false
  end
  return vim.startswith(vim.uri_from_bufnr(buf), "file://")
end

vim.schedule(function()
  vim.diagnostic.config({
    severity_sort = true,
    virtual_text = false,
    virtual_lines = {
      highlight_whole_line = true,
    },
    update_in_insert = false,
    float = {
      source = "if_many",
    },
    underline = {
      severity = vim.diagnostic.severity.HINT,
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

  local ns = vim.api.nvim_create_namespace("deduped_signs")
  local orig_signs_handler = vim.diagnostic.handlers.signs

  vim.diagnostic.handlers.signs = {
    show = function(_, bufnr, _, opts)
      local all_diags = vim.diagnostic.get(bufnr)
      local max_severity_per_line = {}
      for _, d in ipairs(all_diags) do
        local line = d.lnum
        if not max_severity_per_line[line] or d.severity < max_severity_per_line[line].severity then
          max_severity_per_line[line] = d
        end
      end
      local filtered = vim.tbl_values(max_severity_per_line)
      orig_signs_handler.show(ns, bufnr, filtered, opts)
    end,
    hide = function(_, bufnr)
      orig_signs_handler.hide(ns, bufnr)
    end,
  }

  local function autoformat_enabled(buf)
    if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then
      return false
    end
    if require("neoconf").get("autoformat", nil, { bufnr = buf }) == false then
      return false
    end
    return true
  end

  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local bufnr = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)

      -- Detach, not just skip the hints, so no request carries a non-file URI.
      if not on_disk(bufnr) then
        if client then
          vim.lsp.buf_detach_client(bufnr, client.id)
        end
        return
      end

      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })

      if client and client.name == "eslint" then
        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer = bufnr,
          callback = function()
            if not autoformat_enabled(bufnr) then
              return
            end
            vim.cmd("EslintFixAll")
          end,
        })
      end

      if client and client.name == "ruff" then
        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer = bufnr,
          callback = function()
            if not autoformat_enabled(bufnr) then
              return
            end
            vim.lsp.buf.code_action({
              context = { only = { "source.fixAll.ruff", "source.organizeImports.ruff" }, diagnostics = {} },
              apply = true,
            })
          end,
        })
      end

      Snacks.keymap.set("n", "<leader>cD", vim.lsp.buf.definition, { buffer = bufnr, desc = "Go to definition" })
      Snacks.keymap.set("n", "<leader>cS", vim.lsp.buf.workspace_symbol, { buffer = bufnr, desc = "Workspace symbols" })

      Snacks.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code action" })
      Snacks.keymap.set({ "n", "v" }, "gra", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code action" })
      Snacks.keymap.set({ "n", "v" }, "gri", vim.lsp.buf.implementation, { buffer = bufnr, desc = "Implementation" })
      Snacks.keymap.set({ "n", "v" }, "grn", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename" })
      Snacks.keymap.set({ "n", "v" }, "grr", vim.lsp.buf.references, { buffer = bufnr, desc = "References" })
      Snacks.keymap.set({ "n", "v" }, "grt", vim.lsp.buf.type_definition, { buffer = bufnr, desc = "Type definition" })
      Snacks.keymap.set("n", "<leader>cA", vim.lsp.codelens.run, { buffer = bufnr, desc = "Run codelens action" })

      Snacks.keymap.set("n", "<leader>cn", vim.diagnostic.goto_next, { buffer = bufnr, desc = "Next diagnostic" })
      Snacks.keymap.set("n", "<leader>cp", vim.diagnostic.goto_prev, { buffer = bufnr, desc = "Previous diagnostic" })

      Snacks.keymap.set("n", "]d", vim.diagnostic.goto_next, { buffer = bufnr, desc = "Next diagnostic" })
      Snacks.keymap.set("n", "[d", vim.diagnostic.goto_prev, { buffer = bufnr, desc = "Previous diagnostic" })
      Snacks.keymap.set("n", "]D", function()
        vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
      end, { buffer = bufnr, desc = "Next error" })
      Snacks.keymap.set("n", "[D", function()
        vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
      end, { buffer = bufnr, desc = "Previous error" })

      Snacks.keymap.set("n", "<leader>cj", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "Signature help" })
    end,
  })
end)
