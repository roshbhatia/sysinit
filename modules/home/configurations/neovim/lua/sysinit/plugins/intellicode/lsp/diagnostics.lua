local M = {}

function M.configure()
  vim.lsp.inlay_hint.enable(true)

  vim.diagnostic.config({
    severity_sort = true,
    virtual_text = false,
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
        [vim.diagnostic.severity.ERROR] = "󰅙 ",
        [vim.diagnostic.severity.HINT] = "", -- Empty on purpose, so it doesn't show in the sign column
        [vim.diagnostic.severity.INFO] = "", -- Empty on purpose, so it doesn't show in the sign column
        [vim.diagnostic.severity.WARN] = "󰀨 ",
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

return M
