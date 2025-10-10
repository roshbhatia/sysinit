local M = {}

function M.setup()
  vim.g.mapleader = " "
  vim.g.maplocalleader = "\\"
  vim.keymap.set("n", "<leader><leader>", ":", { desc = "Command" })
end

return M
