local M = {}

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    pcall(function()
      vim.cmd("silent! redir > ~/.cache/nvim/last-run-messages.log")
      vim.cmd("silent! messages")
      vim.cmd("silent! redir END")
    end)
  end,
})

return M
