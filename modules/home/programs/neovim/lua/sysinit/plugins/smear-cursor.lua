local function hl_hex(name, attr)
  local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
  local v = hl and hl[attr]
  return v and string.format("#%06x", v) or nil
end

return {
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = function()
      return {
        legacy_computing_symbols_support = true,
        cursor_color = hl_hex("Cursor", "bg") or "none",
        stiffness = 0.5,
        trailing_stiffness = 0.5,
        matrix_pixel_threshold = 0.5,
        smear_between_buffers = false,
      }
    end,
  },
}
