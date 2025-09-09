local M = {}

local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")

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
      icon, color = "󰂅", colors.green
    elseif percent >= 80 then
      icon, color = "󰂁", colors.green
    elseif percent >= 60 then
      icon, color = "󰁿", colors.white
    elseif percent >= 40 then
      icon, color = "󰁽", colors.yellow
    elseif percent >= 20 then
      icon, color = "󰁻", colors.orange
    else
      icon, color = "󰁺", colors.red
    end

    battery:set({
      icon = {
        string = icon,
        color = color,
      },
      label = {
        string = (
          percent >= 100 and tostring(percent) .. "%"
          or percent >= 10 and " " .. tostring(percent) .. "%"
          or "  " .. tostring(percent) .. "%"
        ),
        color = color,
      },
    })
  end)
end

function M.setup()
  battery = sbar.add("item", "battery", {
    position = "right",
    icon = {
      font = settings.fonts.icons.regular,
    },
    label = {
      font = settings.fonts.text.regular,
      width = 40,
    },
    background = { drawing = false },
    padding_left = settings.spacing.widget_spacing,
    padding_right = settings.spacing.widget_spacing,
    update_freq = 120,
    click_script = "open /System/Library/PreferencePanes/Battery.prefPane",
  })

  battery:subscribe("system_woke", function(env)
    get_battery_info()
  end)

  battery:subscribe("power_source_change", function(env)
    get_battery_info()
  end)

  sbar.add("item", "battery_separator", {
    position = "right",
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

  get_battery_info()
end

return M
