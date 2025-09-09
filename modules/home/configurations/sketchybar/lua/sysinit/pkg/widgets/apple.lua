local M = {}

local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")

function M.setup()
  sbar.add("item", { width = 5 })

  local apple = sbar.add("item", "apple", {
    position = "left",
    icon = {
      font = { family = "Symbols Nerd Font Mono", style = "Regular", size = 14.0 },
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
      string = "|",
      font = { family = "TX-02", style = "Bold", size = 18.0 },
      color = colors.white,
    },
    background = { drawing = false },
    label = { drawing = false },
    padding_left = settings.spacing.separator_spacing,
    padding_right = settings.spacing.separator_spacing,
  })
end

return M
