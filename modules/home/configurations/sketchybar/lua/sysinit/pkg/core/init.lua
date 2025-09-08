local M = {}

local sbar = require("sketchybar")
local theme = require("sysinit.pkg.theme")

function M.setup()
  -- Setup bar configuration immediately (no async)
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

  sbar.default({
    background = {
      drawing = false,
    },
    icon = {
      font = theme.fonts.app_icon,
      color = theme.colors.white,
      padding_left = 6,
      padding_right = 4,
    },
    label = {
      font = theme.fonts.text,
      color = theme.colors.white,
      padding_left = 2,
      padding_right = 6,
    },
    padding_left = theme.geometry.item.padding,
    padding_right = theme.geometry.item.padding,
  })
end

return M
