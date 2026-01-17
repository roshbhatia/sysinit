local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")
local utils = require("sysinit.pkg.utils")

local M = {}

function M.setup()
  sbar.add("item", { width = 5 })

  sbar.add("item", "logo", {
    position = "left",
    icon = {
      font = settings.fonts.icons.regular,
      string = " 󱄅",
      padding_left = settings.spacing.section_spacing,
      color = colors.foreground_primary,
    },
    label = { drawing = false },
    background = { drawing = false },
    padding_left = 1,
    padding_right = 1,
  })

  utils.separator("logo_separator", "left")
end

return M
