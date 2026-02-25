vim.lsp.inlay_hint.enable(true)

vim.diagnostic.config({
  severity_sort = true,
  virtual_text = false,
  virtual_lines = {
    highlight_whole_line = true,
  },
  update_in_insert = false,
  float = {
    border = "rounded",
    source = "if_many",
  },
  underline = {
    severity = vim.diagnostic.severity.HINT,
  },
  signs = {
    text = {
      -- All empty on purpose, so it doesn't show in the sign column
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
    -- Gather ALL diagnostics in the buffer (not just the ones passed in)
    local all_diags = vim.diagnostic.get(bufnr)

    -- Keep only the worst diagnostic per line
    local max_severity_per_line = {}
    for _, d in ipairs(all_diags) do
      local line = d.lnum
      if not max_severity_per_line[line] or d.severity < max_severity_per_line[line].severity then
        max_severity_per_line[line] = d
      end
    end

    -- Convert back to list and show only those
    local filtered = vim.tbl_values(max_severity_per_line)
    orig_signs_handler.show(ns, bufnr, filtered, opts)
  end,

  hide = function(_, bufnr)
    orig_signs_handler.hide(ns, bufnr)
  end,
}

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf

    Snacks.keymap.set("n", "<leader>cD", vim.lsp.buf.definition, { buffer = bufnr, desc = "Go to definition" })
    Snacks.keymap.set("n", "<leader>cS", vim.lsp.buf.workspace_symbol, { buffer = bufnr, desc = "Workspace symbols" })

    Snacks.keymap.set({ "n", "v" }, "<leader>ca", function()
      require("fastaction").code_action()
    end, { buffer = bufnr, desc = "Code action" })
    Snacks.keymap.set({ "n", "v" }, "gra", function()
      require("fastaction").code_action()
    end, { buffer = bufnr, desc = "Code action" })
    Snacks.keymap.set({ "n", "v" }, "gri", vim.lsp.buf.implementation, { buffer = bufnr, desc = "Implementation" })
    Snacks.keymap.set({ "n", "v" }, "grn", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename" })
    Snacks.keymap.set({ "n", "v" }, "grr", vim.lsp.buf.references, { buffer = bufnr, desc = "References" })
    Snacks.keymap.set({ "n", "v" }, "grt", vim.lsp.buf.type_definition, { buffer = bufnr, desc = "Type definition" })
    Snacks.keymap.set("n", "<leader>cA", vim.lsp.codelens.run, { buffer = bufnr, desc = "Run codelens action" })

    Snacks.keymap.set("n", "<leader>cn", vim.diagnostic.goto_next, { buffer = bufnr, desc = "Next diagnostic" })
    Snacks.keymap.set("n", "<leader>cp", vim.diagnostic.goto_prev, { buffer = bufnr, desc = "Previous diagnostic" })

    Snacks.keymap.set("n", "<leader>cj", function()
      vim.lsp.buf.signature_help({ border = "rounded" })
    end, { buffer = bufnr, desc = "Signature help" })
  end,
})

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
  "docker_compose_language_service",
  "eslint",
  "gopls",
  "helm_ls",
  "jqls",
  "jsonls",
  "lsp_ai",
  "lua_ls",
  "marksman",
  "nil_ls",
  "nixd",
  "pyright",
  "rust_analyzer",
  "statix",
  "terraformls",
  "tflint",
  "up",
  "yamlls",
}

vim.lsp.enable(servers)
