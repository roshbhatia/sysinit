local M = {}

local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")

function M.setup()
  sbar.bar({
    height = 32,
    color = colors.bar_bg,
    position = "top",
    blur_radius = 40,
    sticky = true,
    shadow = false,
    corner_radius = 10,
    margin = 16,
    y_offset = 48,
    padding_left = 16,
    padding_right = 16,
  })

  sbar.default({
    updates = "when_shown",
    icon = {
      font = {
        family = settings.icon_font,
        style = "Regular",
        size = 14.0,
      },
      color = colors.white,
      padding_left = settings.paddings,
      padding_right = settings.paddings,
    },
    label = {
      font = {
        family = settings.font,
        style = "Medium",
        size = 13.0,
      },
      color = colors.white,
      padding_left = settings.paddings,
      padding_right = settings.paddings,
    },
    background = {
      height = 26,
      corner_radius = 9,
      border_width = 2,
    },
    popup = {
      background = {
        border_width = 2,
        corner_radius = 9,
        border_color = colors.popup.border,
        color = colors.popup.bg,
        shadow = { drawing = true },
      },
      blur_radius = 20,
    },
    padding_left = 5,
    padding_right = 5,
  })
end

return M
