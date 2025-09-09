local M = {}

local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")

function M.setup()
  sbar.add("item", { width = 5 })

  local logo = sbar.add("item", "logo", {
    position = "left",
    icon = {
      font = settings.fonts.icons.regular,
      string = "󱄅",
      padding_left = settings.spacing.section_spacing,
      color = colors.white,
    },
    label = { drawing = false },
    background = { drawing = false },
    padding_left = 1,
    padding_right = 1,
    popup = {
      align = "left",
      topmost = true,
      drawing = false,
    },
  })

  local swap_menus = sbar.add("item", "popup.logo.swap_menus", {
    position = "popup.logo",
    icon = {
      string = "󱀜",
      font = settings.fonts.icons.regular,
      color = colors.white,
    },
    label = {
      string = "Toggle Menus",
      font = settings.fonts.text.regular,
      color = colors.white,
    },
    background = {
      color = colors.blue,
      height = 26,
      corner_radius = 6,
    },
    padding_left = 8,
    padding_right = 8,
    click_script = "sketchybar --trigger swap_menus_and_spaces",
  })

  logo:subscribe("mouse.clicked", function()
    logo:set({ popup = { drawing = "toggle" } })
  end)

  logo:subscribe("mouse.exited.global", function()
    logo:set({ popup = { drawing = false } })
  end)

  sbar.add("item", "logo_separator", {
    position = "left",
    icon = {
      string = "|",
      font = settings.fonts.separators.bold,
      color = colors.white,
    },
    background = { drawing = false },
    label = { drawing = false },
    padding_left = settings.spacing.separator_spacing,
    padding_right = settings.spacing.separator_spacing,
  })
end

return M
