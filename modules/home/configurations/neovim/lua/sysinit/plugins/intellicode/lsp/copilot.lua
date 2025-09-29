local M = {}

function M.setup(client, bufnr)
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

  -- Use the enhanced NES module
  local enhanced_nes = require("sysinit.plugins.intellicode.lsp.nes")
  enhanced_nes.setup_enhanced_display(bufnr)
  enhanced_nes.setup_keymaps(bufnr)
end

return M
