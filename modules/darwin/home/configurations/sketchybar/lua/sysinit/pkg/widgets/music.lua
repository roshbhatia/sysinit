local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")
local utils = require("sysinit.pkg.utils")

local M = {}
local music
local music_separator

local function get_music_info()
  sbar.exec("pgrep -x Music", function(_, exit_code)
    if exit_code ~= 0 then
      utils.animate_visibility({ music, music_separator }, false)
      return
    end

    sbar.exec(
      [[osascript -e 'tell application "Music"
        set playerState to player state as text
        try
          set trackName to name of current track
          set trackArtist to artist of current track
          return trackName & "|" & trackArtist & "|" & playerState
        on error
          return "||stopped"
        end try
      end tell']],
      function(result, info_exit)
        if info_exit ~= 0 or not result then
          utils.animate_visibility({ music, music_separator }, false)
          return
        end

        local title, artist, state = result:match("([^|]*)|([^|]*)|([^|]*)")
        if not title or title == "" then
          utils.animate_visibility({ music, music_separator }, false)
          return
        end

        title = utils.truncate(utils.trim(title), 25)
        artist = utils.truncate(utils.trim(artist), 25)

        local icon = "󰐊"
        local label = title .. "  " .. artist

        if state == "paused" then
          icon = "󰏤"
          label = title .. "  " .. artist .. " (paused)"
        elseif state == "stopped" then
          utils.animate_visibility({ music, music_separator }, false)
          return
        end

        utils.animate(function()
          music:set({
            icon = { string = icon, color = colors.foreground_primary },
            label = { string = label, color = colors.foreground_primary },
            drawing = true,
          })
          music_separator:set({ drawing = true })
        end)
      end
    )
  end)
end

function M.setup()
  music = sbar.add("item", "music", {
    position = "left",
    icon = { font = settings.fonts.icons.regular },
    label = { font = settings.fonts.text.regular },
    background = { drawing = false },
    padding_left = settings.spacing.widget_spacing,
    padding_right = settings.spacing.widget_spacing,
    update_freq = 2,
    drawing = false,
  })

  music_separator = utils.separator("music_separator", "left", { drawing = false })

  music:subscribe("routine", function()
    get_music_info()
  end)

  music:subscribe("mouse.clicked", function()
    sbar.exec("osascript -e 'tell application \"Music\" to playpause'")
    sbar.exec("sleep 0.3 && sketchybar -m --trigger music_update", function() end)
  end)

  music:subscribe("mouse.scrolled", function(env)
    local direction = env.SCROLL_DIRECTION
    if direction == "up" then
      os.execute('osascript -e "tell application \\"Music\\" to set sound volume to (get sound volume) + 10"')
    elseif direction == "down" then
      os.execute('osascript -e "tell application \\"Music\\" to set sound volume to (get sound volume) - 10"')
    end
    get_music_info()
  end)

  music:subscribe("system_woke", function()
    get_music_info()
  end)

  get_music_info()
end

return M
