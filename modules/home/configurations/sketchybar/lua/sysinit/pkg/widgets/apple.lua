local M = {}

local sbar = require("sketchybar")
local theme = require("sysinit.pkg.theme")
local settings = require("sysinit.pkg.config.settings")

function M.setup()
  -- Padding item required because of bracket
  sbar.add("item", { width = 5 })

  local apple = sbar.add("item", "apple", {
    position = "left",
    icon = {
      font = { size = 16.0 },
      string = theme.icons.apple,
      padding_right = 8,
      padding_left = 8,
    },
    label = { drawing = false },
    background = {
      color = theme.colors.bg2,
      border_color = theme.colors.black or theme.colors.grey,
      border_width = 1,
    },
    padding_left = 1,
    padding_right = 1,
  })

  -- Double border for apple using a single item bracket
  sbar.add("bracket", { apple.name }, {
    background = {
      color = 0x00000000,
      height = 30,
      border_color = theme.colors.grey,
    },
  })

  -- Separator between apple logo and front app
  sbar.add("item", "apple_separator", {
    position = "left",
    icon = {
      string = "│",
      font = {
        family = settings.font.text,
        style = settings.font.style_map["Regular"],
        size = 12.0,
      },
      color = theme.colors.grey,
    },
    background = { drawing = false },
    label = { drawing = false },
    padding_left = 8,
    padding_right = 8,
  })
end

return M
