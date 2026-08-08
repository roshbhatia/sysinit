local config = require("sysinit.pkg.config")
local display = require("sysinit.pkg.core.display")

local monospace_font = config.font.monospace
local font_size = display.get_font_size(config.font.size or 11.0)
local icon_font = config.font.icons or "Symbols Nerd Font Mono"
local configured_icon_size = config.font.iconSize
local icon_size = (configured_icon_size and configured_icon_size > 0) and configured_icon_size
  or ((icon_font == monospace_font) and font_size or (font_size + 2.0))
local icon_y_offset = config.font.iconYOffset or 0
local label_y_offset = config.font.labelYOffset or 0
local separator_y_offset = config.font.separatorYOffset or 0

return {
  icon_y_offset = icon_y_offset,
  label_y_offset = label_y_offset,
  separator_y_offset = separator_y_offset,

  fonts = {
    text = {
      regular = { family = monospace_font, style = "Regular", size = font_size },
      bold = { family = monospace_font, style = "Bold", size = font_size },
    },
    icons = {
      regular = { family = icon_font, style = "Regular", size = icon_size },
    },
    separators = {
      bold = { family = monospace_font, style = "Regular", size = font_size },
    },
  },

  spacing = {
    paddings = 3,
    widget_spacing = 6,
    section_spacing = 10,
    separator_spacing = 10,
  },
}
