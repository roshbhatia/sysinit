local config = require("sysinit.pkg.config")

local monospace_font = config.font.monospace

return {
  fonts = {
    text = {
      regular = { family = monospace_font, style = "Regular", size = 11.0 },
      bold = { family = monospace_font, style = "Bold", size = 11.0 },
    },
    icons = {
      regular = { family = "Symbols Nerd Font Mono", style = "Regular", size = 11.0 },
    },
    separators = {
      bold = { family = monospace_font, style = "Bold", size = 18.0 },
    },
  },

  spacing = {
    paddings = 3,
    widget_spacing = 6,
    section_spacing = 10,
    separator_spacing = 10,
  },
}
