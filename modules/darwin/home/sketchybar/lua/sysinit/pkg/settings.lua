local config = require("sysinit.pkg.config")

local monospace_font = config.font.monospace
local font_size = config.font.size or 11.0
local icon_font = config.font.icons or "Symbols Nerd Font Mono"
-- When the icon font matches the text font the glyphs share the same em-square;
-- no size bump needed. For a separate symbols font bump slightly so glyphs fill the bar.
local icon_size = (icon_font == monospace_font) and font_size or (font_size + 2.0)
local icon_y_offset = config.font.iconYOffset or 0
local label_y_offset = config.font.labelYOffset or 0

return {
  icon_y_offset = icon_y_offset,
  label_y_offset = label_y_offset,

  fonts = {
    text = {
      regular = { family = monospace_font, style = "Regular", size = font_size },
      bold = { family = monospace_font, style = "Bold", size = font_size },
    },
    icons = {
      regular = { family = icon_font, style = "Regular", size = icon_size },
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
