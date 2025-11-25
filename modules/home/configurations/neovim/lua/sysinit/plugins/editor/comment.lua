local M = {}

M.plugins = {
  {
    "nvim-mini/mini.comment",
    event = "BufReadPost",
    version = "*",
  },
}

return M
