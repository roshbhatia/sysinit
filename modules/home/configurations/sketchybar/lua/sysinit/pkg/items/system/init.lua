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
      icon = {
        string = icon,
        color = color,
      },
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
      icon = {
        string = icon,
      },
      label = { string = volume .. "%" },
    })
  end)
end

local function get_time()
  sbar.exec("date +'%I:%M %p %Z'", function(local_result, exit_code)
    if exit_code ~= 0 then
      return
    end

    sbar.exec("TZ=UTC date +'%H:%M UTC'", function(utc_result, exit_code)
      if exit_code ~= 0 then
        return
      end

      local local_time = local_result:gsub("%s+", " "):gsub("^%s*", ""):gsub("%s*$", "")
      local utc_time = utc_result:gsub("%s+", " "):gsub("^%s*", ""):gsub("%s*$", "")

      clock:set({
        icon = { string = "󰃰" },
        label = { string = local_time },
      })

      utc_clock:set({
        icon = { string = "󰖟" },
        label = { string = utc_time },
      })
    end)
  end)
end

local function update_clocks()
  get_time()
end

function M.setup()
  clock = sbar.add("item", "clock", {
    position = "right",
    label = { font = theme.fonts.text_medium },
    background = { drawing = false },
    padding_left = 4,
    padding_right = 4,
    update_freq = 60,
    click_script = "open /System/Applications/Calendar.app",
  })

  utc_clock = sbar.add("item", "utc_clock", {
    position = "right",
    label = { font = theme.fonts.text_medium },
    background = { drawing = false },
    padding_left = 4,
    padding_right = 8,
    update_freq = 60,
  })

  battery = sbar.add("item", "battery", {
    position = "right",
    background = { drawing = false },
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
    icon = {
      string = "󰕾",
    },
    background = { drawing = false },
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
    },
  })

  local volume_popup = sbar.add("item", "volume.popup", {
    position = "popup.volume",
    label = { string = "Volume Control" },
    background = { drawing = false },
  })

  volume_item:subscribe("volume_change", function(env)
    get_volume_info()
  end)

  volume_item:subscribe("mouse.entered", function(env)
    sbar.set("volume", { popup = { drawing = true } })
  end)

  volume_item:subscribe("mouse.exited", function(env)
    sbar.set("volume", { popup = { drawing = false } })
  end)

  get_battery_info()
  get_volume_info()
  get_time()
end

return M
