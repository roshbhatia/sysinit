local M = {}

function M.setup()
  vim.opt.shortmess:append("A")
  vim.opt.autoread = true
  
  vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    pattern = "*",
    command = "if mode() != 'c' | checktime | endif",
  })
  
  vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "*",
    command = "checktime",
  })
end

return M
