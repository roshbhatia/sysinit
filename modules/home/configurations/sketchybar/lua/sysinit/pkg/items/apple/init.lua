local M = {}

local sbar = require("sketchybar")
local theme = require("sysinit.pkg.theme")

function M.setup()
  -- Padding item required because of bracket
  sbar.add("item", { width = 5 })

  local apple = sbar.add("item", "apple", {
    position = "left",
    icon = {
      font = {
        family = theme.fonts.app_icon:match("([^:]+)"),
        style = theme.fonts.app_icon:match(":([^:]+)"),
        size = 16.0,
      },
      string = theme.icons.apple,
      padding_right = 8,
      padding_left = 8,
      color = theme.colors.white,
    },
    label = { drawing = false },
    background = {
      color = theme.colors.item_bg,
      border_color = theme.colors.muted,
      border_width = 1,
      corner_radius = theme.geometry.item.corner_radius,
      height = theme.geometry.item.height,
    },
    padding_left = 1,
    padding_right = 1,
  })

  -- Double border for apple using a single item bracket
  sbar.add("bracket", "apple_bracket", { apple.name }, {
    background = {
      color = "0x00000000", -- transparent
      height = 30,
      border_color = theme.colors.accent,
      border_width = 1,
      corner_radius = theme.geometry.item.corner_radius + 2,
    },
  })

  -- Padding item required because of bracket
  sbar.add("item", { width = 7 })
end

return M
