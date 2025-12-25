local M = {}

function M.setup()
  vim.keymap.set("n", "<leader>bp", vim.cmd("bprevious"), { desc = "Buffer: previous" })
  vim.keymap.set("n", "<leader>bn", vim.cmd("bnext"), { desc = "Buffer: next" })
end

return M
