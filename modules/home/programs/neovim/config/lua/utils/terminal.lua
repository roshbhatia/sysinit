local M = {}

local TRANSPARENT_TERMINALS = {
  kitty = true,
  alacritty = true,
  wezterm = true,
  ghostty = true,
  foot = true,
  contour = true,
  rio = true,
}

function M.is_transparent()
  if not vim.env.LS_COLORS or vim.env.LS_COLORS == "" then
    return false
  end

  if vim.env.KITTY_WINDOW_ID or vim.env.WEZTERM_PANE or vim.env.WT_SESSION then
    return true
  end

  local term_program = vim.env.TERM_PROGRAM

  if term_program and TRANSPARENT_TERMINALS[term_program:lower()] then
    return true
  end

  local colorterm = vim.env.COLORTERM
  if colorterm == "truecolor" or colorterm == "24bit" then
    return true
  end

  local term = vim.env.TERM or ""
  if term:match("256color") or term:match("direct") then
    return true
  end

  return false
end

return M
