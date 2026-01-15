local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")
local utils = require("sysinit.pkg.utils")

local M = {}

local clock
local utc_clock

local function get_time()
  sbar.exec("date +'%I:%M %p %Z'", function(local_result, local_exit_code)
    if local_exit_code ~= 0 then
      return
    end

    sbar.exec("TZ=UTC date +'%H:%M UTC'", function(utc_result, utc_exit_code)
      if utc_exit_code ~= 0 then
        return
      end

      local local_time = utils.trim(local_result)
      local utc_time = utils.trim(utc_result)

      utils.animate(function()
        clock:set({
          icon = { string = " " },
          label = { string = local_time },
        })

        utc_clock:set({
          icon = { string = "󰖟 " },
          label = { string = utc_time },
        })
      end)
    end)
  end)
end

function M.setup()
  clock = sbar.add("item", "clock", {
    position = "right",
    icon = { font = settings.fonts.icons.regular },
    label = { font = settings.fonts.text.regular },
    background = { drawing = false },
    padding_left = settings.spacing.widget_spacing,
    padding_right = settings.spacing.widget_spacing,
    update_freq = 10,
  })

  clock:subscribe("routine", get_time)

  sbar.add("item", "time_separator", {
    position = "right",
    icon = {
      string = "•",
      font = settings.fonts.text.regular,
      color = colors.foreground_muted,
    },
    background = { drawing = false },
    label = { drawing = false },
    padding_left = 4,
    padding_right = 6,
  })

  utc_clock = sbar.add("item", "utc_clock", {
    position = "right",
    icon = { font = settings.fonts.icons.regular },
    label = { font = settings.fonts.text.regular },
    background = { drawing = false },
    padding_left = settings.spacing.widget_spacing,
    padding_right = settings.spacing.widget_spacing,
    update_freq = 60,
  })

  utc_clock:subscribe("routine", get_time)

  utils.separator("clock_separator", "right")

  get_time()
end

return M
