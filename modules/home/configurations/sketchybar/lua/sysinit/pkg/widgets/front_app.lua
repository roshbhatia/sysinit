local M = {}

local sbar = require("sketchybar")
local theme = require("sysinit.pkg.theme")
local settings = require("sysinit.pkg.config.settings")

local app_icons = {
  [".firefox-old"] = "",
  ["Activity Monitor"] = "󰍉",
  ["App Store"] = "󰀸",
  ["Arc"] = "󰄦",
  ["Books"] = "󱉟",
  ["Calculator"] = "",
  ["Calendar"] = "󰸘",
  ["Code - Insiders"] = "󰨞",
  ["Code"] = "󰨞",
  ["Discord"] = "󰙯",
  ["Ferdium"] = "󰙯",
  ["Finder"] = "󰀶",
  ["Firefox"] = "",
  ["Google Chrome"] = "",
  ["Mail"] = "󰇰",
  ["Messages"] = "󰍡",
  ["Messenger"] = "󰍡",
  ["Music"] = "",
  ["Notes"] = "󰎞",
  ["Notion"] = "󰈙",
  ["Outlook"] = "󰇰",
  ["Podcasts"] = "",
  ["Safari"] = "󰀻",
  ["Slack"] = "󰒱",
  ["Spotify"] = "",
  ["System Preferences"] = "",
  ["Terminal"] = "",
  ["Visual Studio Code - Insiders"] = "󰨞",
  ["Visual Studio Code"] = "󰨞",
  ["Wezterm"] = "",
  ["Xcode"] = "󰡯",
  ["Zoom"] = "󰍫",
  ["iTerm2"] = "",
  ["wezterm-gui"] = "",
}

local app_display_names = {
  [".firefox-old"] = "Firefox",
  ["Activity Monitor"] = "Activity Monitor",
  ["App Store"] = "App Store",
  ["System Preferences"] = "System Preferences",
  ["Visual Studio Code"] = "VS Code",
  ["wezterm-gui"] = "WezTerm",
}

local function get_front_app()
  sbar.exec(
    "osascript -e 'tell application \"System Events\" to get name of first application process whose frontmost is true'",
    function(result, exit_code)
      if exit_code ~= 0 then
        return
      end

      local app = result:gsub("%s+", "")
      if app == "" then
        front_app:set({ drawing = false })
        return
      end

      local display_name = app_display_names[app] or app
      front_app:set({
        icon = { string = app_icons[app] or "󰘔" },
        label = { string = display_name },
        drawing = true,
      })
    end
  )
end

function M.setup()
  front_app = sbar.add("item", "front_app", {
    position = "left",
    background = {
      drawing = false,
    },
    padding_left = 8,
    padding_right = 8,
  })

  front_app:subscribe("front_app_switched", function(env)
    get_front_app()
  end)

  get_front_app()
end

return M
