local M = {}

local sbar = require("sketchybar")
local theme = require("sysinit.pkg.theme")

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
      icon, color = "󰂄", theme.colors.accent
    elseif percent >= 80 then
      icon, color = "󰁹", theme.colors.white
    elseif percent >= 60 then
      icon, color = "󰂀", theme.colors.white
    elseif percent >= 40 then
      icon, color = "󰁾", theme.colors.accent
    elseif percent >= 20 then
      icon, color = "󰁼", theme.colors.accent
    else
      icon, color = "󰁺", theme.colors.accent
    end

    battery:set({
      icon = { string = icon, color = color },
      label = { string = percent .. "%", color = color },
    })
  end)
end

local function get_volume_info()
  sbar.exec("osascript -e 'output volume of (get volume settings)'", function(result, exit_code)
    if exit_code ~= 0 then
      return
    end

    local volume = tonumber(result)
    if not volume then
      return
    end

    local icon
    if volume == 0 then
      icon = "󰝟"
    elseif volume < 33 then
      icon = "󰕿"
    elseif volume < 66 then
      icon = "󰖀"
    else
      icon = "󰕾"
    end

    volume_item:set({
      icon = { string = icon },
      label = { string = volume .. "%" },
    })
  end)
end

local function get_time()
  sbar.exec("date +'%H:%M'", function(result, exit_code)
    if exit_code ~= 0 then
      return
    end
    clock:set({
      label = { string = result:gsub("%s+", "") },
    })
  end)
end

local function update_clock()
  get_time()
  sbar.exec("sleep 60", update_clock)
end

function M.setup()
  clock = sbar.add("item", "clock", {
    position = "right",
    label = { font = theme.fonts.text_medium },
    background = {
      corner_radius = theme.geometry.item.corner_radius,
      height = theme.geometry.item.height,
    },
    padding_left = 8,
    padding_right = 8,
    update_freq = 30,
    click_script = "open /System/Applications/Calendar.app",
  })

  battery = sbar.add("item", "battery", {
    position = "right",
    background = {
      corner_radius = theme.geometry.item.corner_radius,
      height = theme.geometry.item.height,
    },
    padding_left = 8,
    padding_right = 8,
    update_freq = 120,
    click_script = "open /System/Library/PreferencePanes/Battery.prefPane",
  })

  battery:subscribe({ "system_woke", "power_source_change" }, function(env)
    get_battery_info()
  end)

  volume_item = sbar.add("item", "volume", {
    position = "right",
    icon = { string = "󰕾" },
    background = {
      corner_radius = theme.geometry.item.corner_radius,
      height = theme.geometry.item.height,
    },
    padding_left = 8,
    padding_right = 8,
    popup = {
      background = {
        color = theme.colors.popup_bg,
        corner_radius = 8,
      },
      blur_radius = 30,
      height = 35,
      y_offset = 10,
      padding_left = 10,
      padding_right = 10,
    },
    click_script = "sketchybar --set volume popup.drawing=toggle",
  })

  volume_item:subscribe("volume_change", function(env)
    get_volume_info()
  end)

  get_battery_info()
  get_volume_info()
  get_time()
  update_clock()
end

return M
