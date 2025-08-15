local M = {}

function M.setup()
  vim.env.PATH = vim.fn.getenv("PATH")
end

return M

