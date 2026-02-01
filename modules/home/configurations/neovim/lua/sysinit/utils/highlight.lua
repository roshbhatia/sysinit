-- Highlight utilities for working with Neovim highlight groups
local M = {}

--- Get a raw highlight color value with safe fallback
--- @param hl_name string The name of the highlight group
--- @param attr? "fg"|"bg" The attribute to get (default: "fg")
--- @param fallback? string Hex color fallback (default: "#FFFFFF" for fg, "#000000" for bg)
--- @return string Hex color code (e.g., "#FFFFFF")
function M.get_hl_raw_safe(hl_name, attr, fallback)
  attr = attr or "fg"

  -- Set default fallback based on attribute
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

--- Get foreground color from a highlight group with safe fallback
--- @param hl_name string The name of the highlight group
--- @param fallback? string Hex color fallback (default: "#FFFFFF")
--- @return string Hex color code (e.g., "#FFFFFF")
function M.get_fg(hl_name, fallback)
  return M.get_hl_raw_safe(hl_name, "fg", fallback)
end

--- Get background color from a highlight group with safe fallback
--- @param hl_name string The name of the highlight group
--- @param fallback? string Hex color fallback (default: "#000000")
--- @return string Hex color code (e.g., "#000000")
function M.get_bg(hl_name, fallback)
  return M.get_hl_raw_safe(hl_name, "bg", fallback)
end

--- Get multiple colors from a highlight group
--- @param hl_name string The name of the highlight group
--- @return table Table with fg, bg, sp (special) fields as hex colors or nil
function M.get_colors(hl_name)
  local hl = vim.api.nvim_get_hl(0, { name = hl_name, link = false })

  return {
    fg = hl.fg and string.format("#%06x", hl.fg) or nil,
    bg = hl.bg and string.format("#%06x", hl.bg) or nil,
    sp = hl.sp and string.format("#%06x", hl.sp) or nil,
  }
end

return M
