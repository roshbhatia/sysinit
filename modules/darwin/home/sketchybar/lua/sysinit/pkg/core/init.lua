local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")
local layout = require("sysinit.pkg.config").layout

local M = {}

function M.setup()
  sbar.bar({
    height = layout.barHeight,
    color = colors.background_primary,
    position = "top",
    blur_radius = colors.blur_radius,
    shadow = false,
    corner_radius = 10,
    margin = layout.gap,
    y_offset = layout.gap,
    notch_offset = layout.notchOffset,
    padding_left = 8,
    padding_right = 8,
  })

  sbar.default({
    updates = "when_shown",
    icon = {
      font = settings.fonts.icons.regular,
      color = colors.foreground_primary,
      padding_left = settings.spacing.paddings,
      padding_right = settings.spacing.paddings,
      y_offset = settings.icon_y_offset,
    },
    label = {
      font = settings.fonts.text.regular,
      color = colors.foreground_primary,
      padding_left = settings.spacing.paddings,
      padding_right = settings.spacing.paddings,
      y_offset = settings.label_y_offset,
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
      blur_radius = colors.blur_radius,
    },
    padding_left = 5,
    padding_right = 5,
  })
end

return M
