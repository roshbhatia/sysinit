local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")
local utils = require("sysinit.pkg.utils")

local M = {}

local mode_item

local mode_colors = {
  MAIN = colors.foreground_primary,
  SWAP = colors.semantic_warning,
  LOCKED = colors.semantic_error,
}

local function update_mode(mode)
  local mode_label = mode or "MAIN"
  local mode_color = mode_colors[mode_label] or colors.foreground_primary

  utils.animate(function()
    mode_item:set({
      label = {
        string = mode_label,
        font = settings.fonts.text.bold,
        color = mode_color,
      },
      drawing = true,
    })
  end)
end

function M.setup()
  sbar.add("event", "aerospace_mode_changed")

  mode_item = sbar.add("item", "aerospace_mode", {
    position = "left",
    icon = { drawing = false },
    label = {
      string = "MAIN",
      font = settings.fonts.text.bold,
      color = colors.foreground_primary,
    },
    background = { drawing = false },
    padding_left = settings.spacing.widget_spacing,
    padding_right = settings.spacing.widget_spacing,
  })

  utils.separator("mode_separator", "left")

  mode_item:subscribe("aerospace_mode_changed", function(env)
    update_mode(env.MODE)
  end)

  -- Initialize with MAIN mode
  update_mode("MAIN")
end

return M
