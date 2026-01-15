local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")
local utils = require("sysinit.pkg.utils")

local M = {}
local battery

local function get_battery_info()
  sbar.exec("pmset -g batt", function(result, exit_code)
    if exit_code ~= 0 then
      return
    end

    local percent = result:match("(%d+)%%")
    local charging = result:match("AC Power") ~= nil

    if not percent then
      return
    end
    percent = tonumber(percent)

    local icon, color
    if charging then
      icon, color = "󰂅", colors.semantic_success
    elseif percent >= 80 then
      icon, color = "󰂁", colors.semantic_success
    elseif percent >= 60 then
      icon, color = "󰁿", colors.foreground_primary
    elseif percent >= 40 then
      icon, color = "󰁽", colors.semantic_warning
    elseif percent >= 20 then
      icon, color = "󰁻", colors.syntax_constant
    else
      icon, color = "󰁺", colors.semantic_error
    end

    utils.animate(function()
      battery:set({
        icon = {
          string = icon,
          color = color,
        },
        label = {
          string = utils.format_percent(percent),
          color = color,
        },
      })
    end)
  end)
end

function M.setup()
  battery = sbar.add("item", "battery", {
    position = "right",
    icon = { font = settings.fonts.icons.regular },
    label = {
      font = settings.fonts.text.regular,
      width = 40,
    },
    background = { drawing = false },
    padding_left = settings.spacing.widget_spacing,
    padding_right = settings.spacing.widget_spacing,
    update_freq = 10,
    click_script = "open /System/Library/PreferencePanes/Battery.prefPane",
  })

  battery:subscribe("system_woke", function()
    get_battery_info()
  end)

  battery:subscribe("power_source_change", function()
    get_battery_info()
  end)

  utils.separator("battery_separator", "right")

  get_battery_info()
end

return M
