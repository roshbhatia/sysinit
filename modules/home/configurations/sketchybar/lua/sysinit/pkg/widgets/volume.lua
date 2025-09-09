local M = {}

local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")

local volume_percent = sbar.add("item", "volume.percent", {
  position = "right",
  icon = { drawing = false },
  label = {
    string = "100%",
    font = settings.fonts.text.regular,
    color = colors.white,
    width = 40,
  },
  background = { drawing = false },
  update_freq = 5,
  padding_left = 2,
  padding_right = settings.spacing.widget_spacing,
})

local volume_icon = sbar.add("item", "volume.icon", {
  position = "right",
  icon = {
    string = "󰕾",
    font = settings.fonts.icons.regular,
    color = colors.white,
  },
  label = { drawing = false },
  background = { drawing = false },
  padding_left = settings.spacing.widget_spacing,
  padding_right = 0,
})

local volume_slider = sbar.add("slider", "volume.slider", {
  position = "popup.volume.icon",
  slider = {
    highlight_color = colors.accent,
    background = {
      height = 6,
      corner_radius = 3,
      color = colors.popup.bg,
    },
    knob = {
      string = "󰀵",
      font = settings.fonts.icons.small,
      color = colors.accent,
    },
  },
  background = { drawing = false },
  padding_left = 8,
  padding_right = 8,
  click_script = 'osascript -e "set volume output volume $SB_VOLUME"',
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

    local icon = ""
    if volume > 60 then
      icon = "󰕾"
    elseif volume > 30 then
      icon = "󰖀"
    elseif volume > 10 then
      icon = "󰕿"
    elseif volume > 0 then
      icon = "󰕿"
    else
      icon = "󰸈"
    end

    volume_icon:set({ icon = { string = icon } })
    volume_percent:set({
      label = {
        string = (volume >= 100 and tostring(volume) .. "%" or volume >= 10 and " " .. tostring(
          volume
        ) .. "%" or "  " .. tostring(volume) .. "%"),
      },
    })
    volume_slider:set({ slider = { percentage = volume } })
  end)
end

function M.setup()
  sbar.add("item", "volume_separator", {
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

  volume_icon:subscribe("mouse.entered", function()
    volume_icon:set({ popup = { drawing = "toggle" } })
  end)

  volume_icon:subscribe("mouse.exited", function()
    volume_icon:set({ popup = { drawing = false } })
  end)

  volume_percent:subscribe("volume_change", function(env)
    get_volume()
  end)

  volume_percent:subscribe("routine", function(env)
    get_volume()
  end)

  get_volume()
end

return M
