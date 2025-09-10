local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")

local M = {}

local volume_percent = sbar.add("item", "volume.percent", {
  position = "right",
  icon = { drawing = false },
  label = {
    string = "100%",
    font = settings.fonts.text.regular,
    color = colors.foreground_primary,
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
    color = colors.foreground_primary,
  },
  label = { drawing = false },
  background = { drawing = false },
  padding_left = settings.spacing.widget_spacing,
  padding_right = 0,
})

local volume_slider = sbar.add("slider", "volume.slider", 80, {
  position = "right",
  slider = {
    highlight_color = colors.syntax_function,
    background = {
      height = 4,
      corner_radius = 2,
      color = colors.foreground_muted,
    },
    knob = "",
    width = 80,
  },
  background = { drawing = false },
  padding_left = 6,
  padding_right = 6,
  drawing = false,
})

local volume_group_active = false
local hide_timer = nil

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

local function show_volume_slider()
  if hide_timer then
    sbar.exec("pkill -f 'sleep 0.3'")
    hide_timer = nil
  end
  volume_group_active = true
  sbar.animate("sin", 15, function()
    volume_slider:set({ drawing = true })
  end)
end

local function hide_volume_slider()
  volume_group_active = false
  hide_timer = sbar.exec("sleep 0.3", function()
    if not volume_group_active then
      sbar.animate("sin", 15, function()
        volume_slider:set({ drawing = false })
      end)
    end
    hide_timer = nil
  end)
end

function M.setup()
  sbar.add("item", "volume_separator", {
    position = "right",
    icon = {
      string = "|",
      font = settings.fonts.separators.bold,
      color = colors.foreground_primary,
    },
    background = { drawing = false },
    label = { drawing = false },
    padding_left = settings.spacing.separator_spacing,
    padding_right = settings.spacing.separator_spacing,
  })

  volume_icon:subscribe("mouse.entered", function()
    show_volume_slider()
  end)

  volume_icon:subscribe("mouse.exited", function()
    hide_volume_slider()
  end)

  volume_slider:subscribe("mouse.entered", function()
    show_volume_slider()
  end)

  volume_slider:subscribe("mouse.exited", function()
    hide_volume_slider()
  end)

  volume_icon:subscribe("mouse.scrolled", function(env)
    local direction = env.SCROLL_DIRECTION
    if direction == "up" then
      os.execute(
        'osascript -e "set volume output volume ((output volume of (get volume settings)) + 5)"'
      )
    elseif direction == "down" then
      os.execute(
        'osascript -e "set volume output volume ((output volume of (get volume settings)) - 5)"'
      )
    end
    get_volume()
  end)

  volume_percent:subscribe("volume_change", function()
    get_volume()
  end)

  volume_percent:subscribe("routine", function()
    get_volume()
  end)

  volume_slider:subscribe("volume_change", function()
    get_volume()
  end)

  volume_slider:subscribe("mouse.clicked", function(env)
    local percentage = env.PERCENTAGE
    if percentage then
      os.execute('osascript -e "set volume output volume ' .. percentage .. '"')
      get_volume()
    end
  end)

  volume_slider:subscribe("mouse.dragged", function(env)
    local percentage = env.PERCENTAGE
    if percentage then
      os.execute('osascript -e "set volume output volume ' .. percentage .. '"')
      get_volume()
    end
  end)

  get_volume()
end

return M
