local M = {}

function M.setup()
  vim.opt.shortmess:append("A")
  vim.opt.autoread = true

  local function check_file_changes()
    if vim.fn.mode() ~= "c" then
      vim.cmd("checktime")
    end
  end

  vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
    pattern = "*",
    callback = check_file_changes,
  })

  vim.api.nvim_create_autocmd("CursorHold", {
    pattern = "*",
    callback = function()
      if vim.bo.buftype == "" then
        check_file_changes()
      end
    end,
  })
end

return M
