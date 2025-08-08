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
        stiffness = 0.9,
        trailing_stiffness = 0.95,
        damping = 0.8,
        max_length = 3,
        max_length_insert_mode = 1,
        color_levels = 8,
        gamma = 1.8,
        matrix_pixel_threshold = 0.9,
        matrix_pixel_threshold_vertical_bar = 0.8,
        legacy_computing_symbols_support = true,
        smear_between_buffers = false,
        smear_replace_mode = false,
        smear_insert_mode = false,
        smear_terminal_mode = false,
        min_horizontal_distance_smear = 2,
        min_vertical_distance_smear = 1,
        time_interval = 12,
        distance_stop_animating = 0.05,
        distance_stop_animating_vertical_bar = 0.1,
        transparent_bg_fallback_color = get_accent_color(),
        max_kept_windows = 20,
        delay_event_to_smear = 0,
        delay_after_key = 2,
      }
    end,
  },
}

return M

