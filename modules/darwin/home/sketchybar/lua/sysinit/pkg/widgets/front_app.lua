local sbar = require("sketchybar")
local settings = require("sysinit.pkg.settings")
local colors = require("sysinit.pkg.colors")
local utils = require("sysinit.pkg.utils")

local M = {}

local front_app

local app_icons = {
  [".firefox-old"] = "",
  ["Activity Monitor"] = "",
  ["App Store"] = "",
  ["Arc"] = "󰄦",
  ["Books"] = "󱉟",
  ["Calculator"] = "󰪚",
  ["Calendar"] = "󰸘",
  ["Claude"] = "",
  ["Discord"] = "󰙯",
  ["Electron"] = "",
  ["Ferdium"] = "󰙯",
  ["Finder"] = "󰀶",
  ["Firefox"] = "",
  ["Google Chrome"] = "󰊯",
  ["Goose"] = "",
  ["Mail"] = "󰇰",
  ["Messages"] = "󰍡",
  ["Messenger"] = "",
  ["MicrosoftOutlook"] = "󰴢",
  ["Music"] = "",
  ["Notes"] = "󰎞",
  ["Outlook"] = "󰴢",
  ["Podcasts"] = "",
  ["Safari"] = "󰀹",
  ["Slack"] = "󰒱",
  ["System Preferences"] = "",
  ["System Settings"] = "",
  ["Wezterm"] = "",
  ["wezterm-gui"] = "",
  ["Xcode"] = "",
  ["Zoom"] = "󰍫",
  ["firefox"] = "",
  ["zoom.us"] = "󰍫",
}

local app_display_names = {
  [".firefox-old"] = "Firefox",
  ["Activity Monitor"] = "Activity Monitor",
  ["App Store"] = "App Store",
  ["MicrosoftOutlook"] = "Outlook",
  ["Visual Studio Code"] = "VS Code",
  ["firefox"] = "Firefox",
  ["wezterm-gui"] = "Wezterm",
  ["zoom.us"] = "Zoom",
}

local function get_front_app()
  sbar.exec(
    "osascript -e 'tell application \"System Events\" to get name of first application process whose frontmost is true'",
    function(result, exit_code)
      if exit_code ~= 0 then
        return
      end

      local app = utils.trim(result)
      if app == "" then
        utils.animate_visibility(front_app, false)
        return
      end

      local display_name = app_display_names[app] or app
      utils.animate(function()
        front_app:set({
          icon = {
            string = app_icons[app] or "󰘔",
            font = settings.fonts.icons.regular,
            color = colors.foreground_primary,
          },
          label = {
            string = display_name,
            font = settings.fonts.text.regular,
            color = colors.foreground_primary,
          },
          drawing = true,
        })
      end)
    end
  )
end

function M.setup()
  front_app = sbar.add("item", "front_app", {
    position = "left",
    icon = {
      font = settings.fonts.icons.regular,
      color = colors.foreground_primary,
    },
    label = {
      font = settings.fonts.text.regular,
      color = colors.foreground_primary,
    },
    background = { drawing = false },
    padding_left = settings.spacing.widget_spacing,
    padding_right = settings.spacing.widget_spacing,
  })

  utils.separator("front_app_separator", "left")

  front_app:subscribe("front_app_switched", function()
    get_front_app()
  end)

  get_front_app()
end

return M
