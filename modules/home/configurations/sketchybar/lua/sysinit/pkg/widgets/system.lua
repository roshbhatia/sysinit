local M = {}

local sbar = require("sketchybar")
local theme = require("sysinit.pkg.theme")
local settings = require("sysinit.pkg.config.settings")

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
      icon, color = "󰂄", theme.colors.green
    elseif percent >= 80 then
      icon, color = "󰁹", theme.colors.white
    elseif percent >= 60 then
      icon, color = "󰂀", theme.colors.white
    elseif percent >= 40 then
      icon, color = "󰁾", theme.colors.yellow
    elseif percent >= 20 then
      icon, color = "󰁼", theme.colors.orange
    else
      icon, color = "󰁺", theme.colors.red
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
  -- Rightmost: Clock
  clock = sbar.add("item", "clock", {
    position = "right",
    background = { drawing = false },
    padding_left = 4,
    padding_right = 4,
    update_freq = 60,
    click_script = "open /System/Applications/Calendar.app",
  })

  utc_clock = sbar.add("item", "utc_clock", {
    position = "right",
    background = { drawing = false },
    padding_left = 4,
    padding_right = 4,
    update_freq = 60,
  })

  -- Separator between clock and battery
  sbar.add("item", "clock_separator", {
    position = "right",
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

  -- Second right: Battery
  battery = sbar.add("item", "battery", {
    position = "right",
    background = { drawing = false },
    padding_left = 4,
    padding_right = 4,
    update_freq = 120,
    click_script = "open /System/Library/PreferencePanes/Battery.prefPane",
  })

  battery:subscribe({ "system_woke", "power_source_change" }, function(env)
    get_battery_info()
  end)

  -- Separator between battery and volume
  sbar.add("item", "battery_separator", {
    position = "right",
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

  get_battery_info()
  get_time()
end

return M
