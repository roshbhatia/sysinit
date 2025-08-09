local M = {}

local workspaces = { "1", "2", "3", "4", "C", "E", "M", "S", "X" }
local currentWorkspaceIndex = 1
local isSwitching = false
local overlay = nil
local switchTimer = nil

local function getCurrentWorkspace()
  local output = hs.execute("aerospace list-workspaces --focused", true)
  return output and output:match("%S+") or "1"
end

local function updateCurrentWorkspaceIndex()
  local current = getCurrentWorkspace()
  for i, w in ipairs(workspaces) do
    if w == current then
      currentWorkspaceIndex = i
      break
    end
  end
end

local function switchToWorkspace(workspace)
  hs.execute("aerospace workspace " .. workspace, true)
end

local function showWorkspaceOverlay(workspace)
  if overlay then
    overlay:delete()
  end

  local mainScreen = hs.screen.mainScreen()
  local screenFrame = mainScreen:fullFrame()

  local overlayFrame = {
    x = screenFrame.x + screenFrame.w / 2 - 100,
    y = screenFrame.y + screenFrame.h / 2 - 100,
    w = 200,
    h = 200,
  }

  overlay = hs.drawing.rectangle(overlayFrame)
  overlay:setFillColor({ alpha = 0.8, red = 0.1, green = 0.1, blue = 0.1 })
  overlay:setStrokeColor({ alpha = 1.0, red = 0.8, green = 0.8, blue = 0.8 })
  overlay:setStrokeWidth(2)
  overlay:setRoundedRectRadii(20, 20)
  overlay:setBehavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
  overlay:setLevel(hs.drawing.windowLevels.modalPanel)

  local textFrame = {
    x = overlayFrame.x,
    y = overlayFrame.y + 50,
    w = overlayFrame.w,
    h = 100,
  }

  local text = hs.drawing.text(textFrame, workspace)
  text:setTextFont("SF Pro Display")
  text:setTextSize(80)
  text:setTextColor({ alpha = 1.0, red = 1.0, green = 1.0, blue = 1.0 })
  text:setTextStyle({
    alignment = "center",
    lineBreak = "wordWrap",
  })
  text:setBehavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
  text:setLevel(hs.drawing.windowLevels.modalPanel + 1)

  overlay:show()
  text:show()

  overlay.text = text
end

local function hideWorkspaceOverlay()
  if overlay then
    if overlay.text then
      overlay.text:delete()
    end
    overlay:delete()
    overlay = nil
  end
end

local function finalizeSwitching()
  if isSwitching then
    local workspace = workspaces[currentWorkspaceIndex]
    switchToWorkspace(workspace)
    hideWorkspaceOverlay()
    isSwitching = false
  end
end

local function nextWorkspace()
  updateCurrentWorkspaceIndex()

  if not isSwitching then
    isSwitching = true
  end

  currentWorkspaceIndex = currentWorkspaceIndex % #workspaces + 1
  local workspace = workspaces[currentWorkspaceIndex]
  showWorkspaceOverlay(workspace)

  -- Reset or create timer
  if switchTimer then
    switchTimer:stop()
  end
  switchTimer = hs.timer.doAfter(0.7, finalizeSwitching)
end

local function previousWorkspace()
  updateCurrentWorkspaceIndex()

  if not isSwitching then
    isSwitching = true
  end

  currentWorkspaceIndex = (currentWorkspaceIndex - 2) % #workspaces + 1
  local workspace = workspaces[currentWorkspaceIndex]
  showWorkspaceOverlay(workspace)

  -- Reset or create timer
  if switchTimer then
    switchTimer:stop()
  end
  switchTimer = hs.timer.doAfter(0.7, finalizeSwitching)
end

local function confirmSwitch()
  if isSwitching and switchTimer then
    switchTimer:stop()
    finalizeSwitching()
  end
end

function M.setup()
  hs.hotkey.bind({ "alt" }, "tab", nil, confirmSwitch, nextWorkspace)
  hs.hotkey.bind({ "alt", "shift" }, "tab", nil, confirmSwitch, previousWorkspace)

  hs.eventtap
    .new({ hs.eventtap.event.types.keyDown }, function(event)
      if isSwitching and event:getKeyCode() == hs.keycodes.map.escape then
        if switchTimer then
          switchTimer:stop()
        end
        hideWorkspaceOverlay()
        isSwitching = false
        return true
      end
      return false
    end)
    :start()

  hs.eventtap
    .new({ hs.eventtap.event.types.flagsChanged }, function(event)
      if isSwitching and not event:getFlags().alt then
        confirmSwitch()
        return true
      end
      return false
    end)
    :start()
end

return M

