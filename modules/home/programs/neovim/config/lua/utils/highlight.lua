local M = {}

function M.get_hl_raw_safe(hl_name, attr, fallback)
  attr = attr or "fg"

  if not fallback then
    fallback = attr == "bg" and "#000000" or "#FFFFFF"
  end

  local hl = vim.api.nvim_get_hl(0, { name = hl_name, link = false })
  local value = hl[attr]

  if value then
    return string.format("#%06x", value)
  end

  return fallback
end

function M.get_fg(hl_name, fallback)
  return M.get_hl_raw_safe(hl_name, "fg", fallback)
end

function M.get_bg(hl_name, fallback)
  return M.get_hl_raw_safe(hl_name, "bg", fallback)
end

function M.get_colors(hl_name)
  local hl = vim.api.nvim_get_hl(0, { name = hl_name, link = false })

  return {
    fg = hl.fg and string.format("#%06x", hl.fg) or nil,
    bg = hl.bg and string.format("#%06x", hl.bg) or nil,
    sp = hl.sp and string.format("#%06x", hl.sp) or nil,
  }
end

return M
