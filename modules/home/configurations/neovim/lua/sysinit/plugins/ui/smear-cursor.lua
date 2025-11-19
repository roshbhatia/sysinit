local M = {}

M.plugins = {
  {
    "sphamba/smear-cursor.nvim",
    event = "CursorMoved",
    opts = {
      legacy_computing_symbols_support = true,
      matrix_pixel_threshold = 0.5,
      stiffness = 0.5,
      trailing_stiffness = 0.5,
    },
  },
}

return M
