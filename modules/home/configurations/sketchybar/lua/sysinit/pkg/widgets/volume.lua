local M = {}

local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")

local volume_icon = sbar.add("item", "volume.icon", {
  position = "right",
  icon = {
    string = "󰕾",
    font = {
      family = settings.icon_font,
      style = "Light",
      size = 14.0,
    },
    color = colors.white,
  },
  label = { drawing = false },
  background = { drawing = false },
})

local volume_percent = sbar.add("item", "volume.percent", {
  position = "right",
  icon = { drawing = false },
  label = {
    string = "??%",
    font = {
      family = settings.font,
      style = "Light",
      size = 13.0,
    },
    color = colors.white,
  },
  background = { drawing = false },
  update_freq = 5,
})

local function get_volume()
  sbar.exec("osascript -e 'output volume of (get volume settings)'", function(result, exit_code)
    if exit_code ~= 0 then
      return
    end

    local volume = tonumber(result)
    if not volume then
      return
    end

    local icon = ""
    if volume > 60 then
      icon = ""
    elseif volume > 30 then
      icon = "󰕾"
    elseif volume > 10 then
      icon = ""
    elseif volume > 0 then
      icon = "󰕿"
    end

    volume_percent:set({ label = { string = volume .. "%" } })
    volume_icon:set({ icon = { string = icon } })
  end)
end

function M.setup()
  volume_percent:subscribe("volume_change", function(env)
    get_volume()
  end)

  volume_percent:subscribe("routine", function(env)
    get_volume()
  end)

  get_volume()
end

return M
