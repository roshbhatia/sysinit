local M = {}

local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")

function M.setup()
  sbar.add("item", { width = 5 })

  local apple = sbar.add("item", "apple", {
    position = "left",
    icon = {
      font = settings.fonts.icons.normal,
      string = "󱄅",
      padding_right = settings.spacing.section_spacing,
      padding_left = settings.spacing.section_spacing,
      color = colors.white,
    },
    label = { drawing = false },
    background = { drawing = false },
    padding_left = 1,
    padding_right = 1,
  })

  sbar.add("item", "apple_separator", {
    position = "left",
    icon = {
      string = "│",
      font = settings.fonts.separators.normal,
      color = colors.grey,
    },
    background = { drawing = false },
    label = { drawing = false },
    padding_left = settings.spacing.separator_spacing,
    padding_right = settings.spacing.separator_spacing,
  })
end

return M
