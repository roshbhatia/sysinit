local M = {}
local codelens = require("sysinit.plugins.intellicode.lsp.codelens")

function M.setup()
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)

      if client and vim.bo[args.buf].filetype == "markdown" and client.server_capabilities then
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
      end

      codelens.setup(args, client)
    end,
  })
end

return M
