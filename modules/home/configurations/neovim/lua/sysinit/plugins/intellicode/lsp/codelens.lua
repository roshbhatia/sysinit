local M = {}

function M.setup(args, client)
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

return M