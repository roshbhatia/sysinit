-- Auto-generated theme configuration
local M = {}

M.colorscheme = "solarized"
M.variant = "dark"
M.transparency = {
  enable = true,
  opacity = 0.900000
}

M.plugins = {
  solarized = {
    plugin = "craftzdog/solarized-osaka.nvim",
    name = "solarized-osaka",
    setup = "solarized-osaka",
    colorscheme = "solarized-osaka"
  }
}

M.palette = {
  accent = "#268bd2",
      accent_dim = "#073642",
      base0 = "#839496",
      base00 = "#657b83",
      base01 = "#586e75",
      base02 = "#073642",
      base03 = "#002b36",
      base1 = "#93a1a1",
      base2 = "#eee8d5",
      base3 = "#fdf6e3",
      bg = "#002b36",
      bg_alt = "#073642",
      blue = "#268bd2",
      comment = "#586e75",
      cyan = "#2aa198",
      fg = "#839496",
      fg_alt = "#657b83",
      green = "#859900",
      magenta = "#d33682",
      orange = "#cb4b16",
      red = "#dc322f",
      violet = "#6c71c4",
      yellow = "#b58900"
}

return M