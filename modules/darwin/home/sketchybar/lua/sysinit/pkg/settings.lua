local config = require("sysinit.pkg.config")

local monospace_font = config.font.monospace
local font_size = config.font.size or 11.0

return {
  fonts = {
    text = {
      regular = { family = monospace_font, style = "Regular", size = font_size },
      bold = { family = monospace_font, style = "Bold", size = font_size },
    },
    icons = {
      regular = { family = "Symbols Nerd Font Mono", style = "Regular", size = font_size },
    },
    separators = {
      bold = { family = monospace_font, style = "Bold", size = font_size + 7.0 },
    },
  },

  spacing = {
    paddings = 3,
    widget_spacing = 6,
    section_spacing = 10,
    separator_spacing = 10,
  },
}
