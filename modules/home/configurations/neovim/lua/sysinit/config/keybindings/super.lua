local M = {}

function M.setup()
  vim.keymap.set("n", "<leader><leader>", ":", { desc = "Command" })
end

return M
