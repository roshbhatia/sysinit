local M = {}

local sbar = require("sketchybar")
local theme = require("sysinit.pkg.theme")

local popup_width = 250

local volume_percent = sbar.add("item", "widgets.volume1", {
  position = "right",
  icon = { drawing = false },
  label = {
    string = "??%",
    padding_left = -1,
    font = {
      family = theme.fonts.numbers:match("([^:]+)"),
      style = theme.fonts.numbers:match(":([^:]+)"),
      size = tonumber(theme.fonts.numbers:match(":([^:]+):([%d.]+)$")) or 12,
    },
  },
  update_freq = 5,
})

local volume_icon = sbar.add("item", "widgets.volume2", {
  position = "right",
  padding_right = -1,
  icon = {
    string = theme.icons.volume._100,
    width = 0,
    align = "left",
    color = theme.colors.grey,
    font = {
      family = theme.fonts.system_icon:match("([^:]+)"),
      style = theme.fonts.style_map["Regular"],
      size = 14.0,
    },
  },
  label = {
    width = 25,
    align = "left",
    font = {
      family = theme.fonts.text:match("([^:]+)"),
      style = theme.fonts.style_map["Regular"],
      size = 14.0,
    },
  },
})

local volume_bracket = sbar.add("bracket", "widgets.volume.bracket", {
  volume_icon.name,
  volume_percent.name,
}, {
  background = { color = theme.colors.bg1 },
  popup = { align = "center" },
})

sbar.add("item", "widgets.volume.padding", {
  position = "right",
  width = theme.geometry.group_paddings,
})

local volume_slider = sbar.add("slider", popup_width, {
  position = "popup." .. volume_bracket.name,
  slider = {
    highlight_color = theme.colors.blue,
    background = {
      height = 6,
      corner_radius = 3,
      color = theme.colors.bg2,
    },
    knob = {
      string = "􀀁",
      drawing = true,
    },
  },
  background = { color = theme.colors.bg1, height = 2, y_offset = -20 },
  click_script = 'osascript -e "set volume output volume $PERCENTAGE"',
})

volume_percent:subscribe("volume_change", function(env)
  local volume = tonumber(env.INFO)
  local icon = theme.icons.volume._0
  if volume > 60 then
    icon = theme.icons.volume._100
  elseif volume > 30 then
    icon = theme.icons.volume._66
  elseif volume > 10 then
    icon = theme.icons.volume._33
  elseif volume > 0 then
    icon = theme.icons.volume._10
  end

  local lead = ""
  if volume < 10 then
    lead = "0"
  end

  volume_icon:set({ label = icon })
  volume_percent:set({ label = lead .. volume .. "%" })
  volume_slider:set({ slider = { percentage = volume } })
end)

local function volume_collapse_details()
  local drawing = volume_bracket:query().popup.drawing == "on"
  if not drawing then
    return
  end
  volume_bracket:set({ popup = { drawing = false } })
  sbar.remove("/volume.device\\.*/")
end

local current_audio_device = "None"
local function volume_toggle_details(env)
  if env.BUTTON == "right" then
    sbar.exec("open /System/Library/PreferencePanes/Sound.prefpane")
    return
  end

  local should_draw = volume_bracket:query().popup.drawing == "off"
  if should_draw then
    volume_bracket:set({ popup = { drawing = true } })
    sbar.exec("SwitchAudioSource -t output -c", function(result)
      current_audio_device = result:sub(1, -2)
      sbar.exec("SwitchAudioSource -a -t output", function(available)
        current = current_audio_device
        local color = theme.colors.grey
        local counter = 0

        for device in string.gmatch(available, "[^\r\n]+") do
          local color = theme.colors.grey
          if current == device then
            color = theme.colors.white
          end
          sbar.add("item", "volume.device." .. counter, {
            position = "popup." .. volume_bracket.name,
            width = popup_width,
            align = "center",
            label = { string = device, color = color },
            click_script = 'SwitchAudioSource -s "'
              .. device
              .. '" && sketchybar --set /volume.device\\.*/ label.color='
              .. theme.colors.grey
              .. " --set $NAME label.color="
              .. theme.colors.white,
          })
          counter = counter + 1
        end
      end)
    end)
  else
    volume_collapse_details()
  end
end

local function volume_scroll(env)
  local delta = env.INFO.delta
  if not (env.INFO.modifier == "ctrl") then
    delta = delta * 10.0
  end

  sbar.exec(
    'osascript -e "set volume output volume (output volume of (get volume settings) + '
      .. delta
      .. ')"'
  )
end

-- Initial volume load
local function get_initial_volume()
  sbar.exec('osascript -e "output volume of (get volume settings)"', function(result)
    local volume = tonumber(result)
    if volume then
      local icon = theme.icons.volume._0
      if volume > 60 then
        icon = theme.icons.volume._100
      elseif volume > 30 then
        icon = theme.icons.volume._66
      elseif volume > 10 then
        icon = theme.icons.volume._33
      elseif volume > 0 then
        icon = theme.icons.volume._10
      end

      local lead = ""
      if volume < 10 then
        lead = "0"
      end

      volume_icon:set({ label = icon })
      volume_percent:set({ label = lead .. volume .. "%" })
      volume_slider:set({ slider = { percentage = volume } })
    end
  end)
end

function M.setup()
  volume_icon:subscribe("mouse.clicked", volume_toggle_details)
  volume_icon:subscribe("mouse.scrolled", volume_scroll)
  volume_percent:subscribe("mouse.clicked", volume_toggle_details)
  volume_percent:subscribe("mouse.exited.global", volume_collapse_details)
  volume_percent:subscribe("mouse.scrolled", volume_scroll)

  -- Add routine update for volume percentage
  volume_percent:subscribe("routine", function(env)
    get_initial_volume()
  end)

  -- Load initial volume
  get_initial_volume()
end

return M
