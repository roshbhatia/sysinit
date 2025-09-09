local M = {}

local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")

function M.setup()
  sbar.add("item", { width = 5 })

  local apple = sbar.add("item", "apple", {
    position = "left",
    icon = {
      font = {
        family = settings.icon_font,
        style = "Regular",
        size = 16.0,
      },
      string = "󱄅",
      padding_right = 8,
      padding_left = 8,
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
      font = {
        family = settings.font,
        style = "Regular",
        size = 12.0,
      },
      color = colors.grey,
    },
    background = { drawing = false },
    label = { drawing = false },
    padding_left = 8,
    padding_right = 8,
  })
end

return M
