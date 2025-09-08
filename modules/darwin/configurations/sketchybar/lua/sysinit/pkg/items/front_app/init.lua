local M = {}

local sbar = require("sketchybar")
local theme = require("sysinit.pkg.theme")

local app_icons = {
  ["Finder"] = ":finder:",
  ["Safari"] = ":safari:",
  ["Google Chrome"] = ":google_chrome:",
  ["Arc"] = ":arc:",
  ["Firefox"] = ":firefox:",
  ["Visual Studio Code"] = ":code:",
  ["Code"] = ":code:",
  ["Terminal"] = ":terminal:",
  ["iTerm2"] = ":iterm2:",
  ["Wezterm"] = ":terminal:",
  ["Discord"] = ":discord:",
  ["Ferdium"] = ":discord:",
  ["Slack"] = ":slack:",
  ["Notion"] = ":notion:",
  ["Spotify"] = ":spotify:",
  ["Mail"] = ":mail:",
  ["Outlook"] = ":mail:",
  ["Messages"] = ":messages:",
  ["Calendar"] = ":calendar:",
  ["Notes"] = ":notes:",
  ["Calculator"] = ":calculator:",
  ["Activity Monitor"] = ":activity_monitor:",
  ["App Store"] = ":app_store:",
  ["System Preferences"] = ":gear:",
  ["Xcode"] = ":xcode:",
  ["Zoom"] = ":zoom:"
}

local function get_front_app()
  sbar.exec('osascript -e \'tell application "System Events" to get name of first application process whose frontmost is true\'', function(result, exit_code)
    if exit_code ~= 0 then return end
    
    local app = result:gsub("%s+", "")
    if app == "" then
      front_app:set({ drawing = false })
      return
    end
    
    front_app:set({
      icon = { string = app_icons[app] or ":default:" },
      label = { string = app },
      drawing = true
    })
  end)
end

function M.setup()
  front_app = sbar.add("item", "front_app", {
    position = "left",
    background = {
      corner_radius = theme.geometry.item.corner_radius,
      height = theme.geometry.item.height
    },
    padding_left = 8,
    padding_right = 8
  })

  front_app:subscribe("front_app_switched", function(env)
    get_front_app()
  end)

  get_front_app()
end

return M