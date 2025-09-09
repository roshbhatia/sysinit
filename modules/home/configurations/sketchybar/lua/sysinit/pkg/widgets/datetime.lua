local M = {}

local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")

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
        icon = { string = " " },
        label = { string = local_time },
      })

      utc_clock:set({
        icon = { string = "󰖟 " },
        label = { string = utc_time },
      })
    end)
  end)
end

function M.setup()
  clock = sbar.add("item", "clock", {
    position = "right",
    icon = {
      font = settings.fonts.icons.regular,
    },
    label = {
      font = settings.fonts.text.regular,
    },
    background = { drawing = false },
    padding_left = settings.spacing.widget_spacing,
    padding_right = settings.spacing.widget_spacing,
    update_freq = 60,
  })

  sbar.add("item", "time_separator", {
    position = "right",
    icon = {
      string = "•",
      font = settings.fonts.text.regular,
      color = colors.green,
    },
    background = { drawing = false },
    label = { drawing = false },
    padding_left = 4,
    padding_right = 6,
  })

  utc_clock = sbar.add("item", "utc_clock", {
    position = "right",
    icon = {
      font = settings.fonts.icons.regular,
    },
    label = {
      font = settings.fonts.text.regular,
    },
    background = { drawing = false },
    padding_left = settings.spacing.widget_spacing,
    padding_right = settings.spacing.widget_spacing,
    update_freq = 60,
  })

  sbar.add("item", "clock_separator", {
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

  get_time()
end

return M
