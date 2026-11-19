local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")
local utils = require("sysinit.pkg.utils")

local M = {}

function M.setup()
  sbar.add("item", "logo", {
    position = "left",
    icon = {
      font = settings.fonts.icons.regular,
      string = "󱄅",
      color = colors.foreground_primary,
    },
    label = { drawing = false },
    background = { drawing = false },
    padding_left = settings.spacing.widget_spacing,
    padding_right = settings.spacing.widget_spacing,
  })

  utils.separator("logo_separator", "left")
end

return M
