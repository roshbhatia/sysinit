local theme = require("sysinit.pkg.theme")
local M = {}

local switcherUIPrefs = nil

local windowSwitcher = nil
local tapCmdTab = nil

local function initWindowSwitcher()
  switcherUIPrefs = theme.getWindowSwitcherPrefs()
  windowSwitcher = hs.window.switcher.new(
    hs.window.filter.new():setCurrentSpace(true):setDefaultFilter({}),
    switcherUIPrefs
  )
end

local function mapCmdTab(event)
  local flags = event:getFlags()
  local keyCode = event:getKeyCode()
  local tabKey = hs.keycodes.map["tab"]

  if keyCode ~= tabKey then
    return false
  end

  if flags.cmd and not flags.shift and not flags.alt and not flags.ctrl then
    if windowSwitcher then
      windowSwitcher:next()
    end
    return true
  end

  if flags.cmd and flags.shift and not flags.alt and not flags.ctrl then
    if windowSwitcher then
      windowSwitcher:previous()
    end
    return true
  end

  return false
end

function M.setup()
  initWindowSwitcher()

  if tapCmdTab then
    tapCmdTab:stop()
    tapCmdTab = nil
  end

  tapCmdTab = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, mapCmdTab)

  if tapCmdTab then
    tapCmdTab:start()

    if not tapCmdTab:isEnabled() then
      hs.console.printStyledtext("Warning: Failed to enable cmd+tab event tap")
    end
  else
    hs.console.printStyledtext("Error: Failed to create cmd+tab event tap")
  end
end

return M
