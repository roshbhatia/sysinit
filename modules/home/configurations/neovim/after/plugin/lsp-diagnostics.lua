vim.lsp.inlay_hint.enable(true)

vim.diagnostic.config({
  severity_sort = true,
  virtual_text = false,
  virtual_lines = true,
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
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.HINT] = "", -- Empty on purpose, so it doesn't show in the sign column
      [vim.diagnostic.severity.INFO] = "", -- Empty on purpose, so it doesn't show in the sign column
      [vim.diagnostic.severity.WARN] = "",
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
