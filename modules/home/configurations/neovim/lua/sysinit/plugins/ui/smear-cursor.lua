local M = {}

local function get_accent_color()
  local hl = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  return hl and hl.bg and string.format("#%06x", hl.bg) or "#1e1e2e"
end

M.plugins = {
  {
    "sphamba/smear-cursor.nvim",
    enabled = true,
    opts = function()
      return {
        stiffness = 1.0,
        trailing_stiffness = 1.0,
        damping = 0.9,
        matrix_pixel_threshold = 1.0,
        legacy_computing_symbols_support = true,
        min_horozontal_distance_smear = 1000,
        smear_replace_mode = false,
        smear_insert_mode = false,
        transparent_bg_fallback_color = get_accent_color(),
      }
    end,
  },
}

return M
