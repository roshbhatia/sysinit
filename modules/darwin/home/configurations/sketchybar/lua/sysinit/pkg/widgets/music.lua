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

    sbar.exec("osascript -e 'tell application \"Music\" to get player state as text'", function(state, state_exit)
      if state_exit ~= 0 then
        utils.animate_visibility({ music, music_separator }, false)
        sbar.refresh("music")
        return
      end

      local player_state = utils.trim(state)
      if player_state ~= "playing" then
        utils.animate_visibility({ music, music_separator }, false)
        sbar.refresh("music")
        return
      end

      sbar.exec(
        [[osascript -e 'tell application "Music"
        set trackName to name of current track
        set trackArtist to artist of current track
        return trackName & "|" & trackArtist
      end tell']],
        function(result, info_exit)
          if info_exit ~= 0 or not result then
            utils.animate_visibility({ music, music_separator }, false)
            sbar.refresh("music")
            return
          end

          local title, artist = result:match("([^|]+)|([^|]+)")
          if not title then
            utils.animate_visibility({ music, music_separator }, false)
            sbar.refresh("music")
            return
          end

          title = utils.truncate(utils.trim(title), 25)
          artist = utils.truncate(utils.trim(artist), 25)

          utils.animate(function()
            music:set({
              icon = { string = "󰐊", color = colors.foreground_primary },
              label = { string = title .. " x " .. artist, color = colors.foreground_primary },
              drawing = true,
            })
            music_separator:set({ drawing = true })
            sbar.refresh("music")
          end)
        end
      )
    end)
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
    update_freq = 0.5,
    drawing = false,
  })

  music_separator = utils.separator("music_separator", "left", { drawing = false })

  music:subscribe("routine", function()
    get_music_info()
  end)

  music:subscribe("mouse.clicked", function()
    sbar.exec("osascript -e 'tell application \"Music\" to playpause'")
    sbar.refresh("music")
  end)

  music:subscribe("mouse.scrolled", function(env)
    local direction = env.SCROLL_DIRECTION
    if direction == "up" then
      os.execute('osascript -e "tell application \\"Music\\" to set sound volume to (get sound volume) + 10"')
    elseif direction == "down" then
      os.execute('osascript -e "tell application \\"Music\\" to set sound volume to (get sound volume) - 10"')
    end
    sbar.refresh("music")
  end)

  music:subscribe("system_woke", function()
    get_music_info()
  end)

  get_music_info()
end

return M
