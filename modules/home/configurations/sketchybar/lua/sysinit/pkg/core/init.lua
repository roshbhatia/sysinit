local M = {}

local sbar = require("sketchybar")
local theme = require("sysinit.pkg.theme")
local settings = require("sysinit.pkg.config.settings")

function M.setup()
  sbar.bar({
    height = theme.geometry.bar.height,
    color = theme.colors.bar_bg,
    position = "top",
    blur_radius = 40,
    sticky = true,
    shadow = true,
    corner_radius = theme.geometry.bar.corner_radius,
    margin = theme.geometry.bar.margin,
    y_offset = theme.geometry.bar.y_offset,
    padding_left = theme.geometry.bar.padding,
    padding_right = theme.geometry.bar.padding,
  })

  -- Equivalent to the --default domain
  sbar.default({
    updates = "when_shown",
    icon = {
      font = {
        family = settings.font.text,
        style = settings.font.style_map["Bold"],
        size = 14.0,
      },
      color = theme.colors.white,
      padding_left = settings.paddings,
      padding_right = settings.paddings,
      background = { image = { corner_radius = 9 } },
    },
    label = {
      font = {
        family = settings.font.text,
        style = settings.font.style_map["Semibold"],
        size = 13.0,
      },
      color = theme.colors.white,
      padding_left = settings.paddings,
      padding_right = settings.paddings,
    },
    background = {
      height = 28,
      corner_radius = 9,
      border_width = 2,
      border_color = theme.colors.bg2,
      image = {
        corner_radius = 9,
        border_color = theme.colors.grey,
        border_width = 1,
      },
    },
    popup = {
      background = {
        border_width = 2,
        corner_radius = 9,
        border_color = theme.colors.accent,
        color = theme.colors.popup_bg,
        shadow = { drawing = true },
      },
      blur_radius = 50,
    },
    padding_left = 5,
    padding_right = 5,
    scroll_texts = true,
  })
end

return M
