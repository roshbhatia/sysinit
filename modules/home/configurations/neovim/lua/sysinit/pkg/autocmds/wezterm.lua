local M = {}

function M.setup()
  vim.fn.system('printf "\\033]1337;SetUserVar=IS_NVIM=%s\\007" "true"')

  vim.api.nvim_create_autocmd("VimLeave", {
    callback = function()
      pcall(function()
        vim.fn.system('printf "\\033]1337;SetUserVar=IS_NVIM=%s\\007" "false"')
      end)
    end,
  })
end

return M
