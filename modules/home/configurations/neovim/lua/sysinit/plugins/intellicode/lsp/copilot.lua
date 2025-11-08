local M = {}

function M.setup(client, bufnr)
  local au = vim.api.nvim_create_augroup("copilotlsp.init", { clear = true })

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
end

return M
