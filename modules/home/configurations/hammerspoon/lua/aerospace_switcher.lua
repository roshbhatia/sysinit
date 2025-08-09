local M = {}

local workspaces = { "1", "2", "3", "4", "C", "E", "M", "S", "X" }
local currentWorkspaceIndex = 1
local isVisible = false
local chooser = nil
local workspaceCache = {}
local cacheExpiry = 2 -- Cache for 2 seconds
local lastCacheUpdate = 0

local function getCurrentWorkspace()
  local output = hs.execute("aerospace list-workspaces --focused", true)
  if output then
    return string.gsub(output, "%s+", "")
  end
  return "1"
end

local function updateCurrentWorkspaceIndex()
  local current = getCurrentWorkspace()
  for i, workspace in ipairs(workspaces) do
    if workspace == current then
      currentWorkspaceIndex = i
      break
    end
  end
end

local function switchToWorkspace(workspace)
  hs.execute("aerospace workspace " .. workspace, true)
end

local function getWorkspaceWindows(workspace)
  -- Check cache first
  local now = hs.timer.secondsSinceEpoch()
  if workspaceCache[workspace] and (now - lastCacheUpdate) < cacheExpiry then
    return workspaceCache[workspace]
  end

  local output = hs.execute(
    "aerospace list-windows --workspace " .. workspace .. " --format '%{app-name}: %{window-title}'",
    true
  )
  local windows = {}
  if output and output ~= "" then
    for line in output:gmatch("[^\r\n]+") do
      if line and line ~= "" then
        table.insert(windows, line)
      end
    end
  end

  -- Cache the result
  workspaceCache[workspace] = windows
  return windows
end

local function updateCache()
  local now = hs.timer.secondsSinceEpoch()
  if (now - lastCacheUpdate) < cacheExpiry then
    return -- Cache still valid
  end

  -- Batch update all workspaces in one command for better performance
  local allWindows = hs.execute(
    "aerospace list-windows --all --format '%{workspace}|%{app-name}: %{window-title}'",
    true
  )

  -- Clear cache
  workspaceCache = {}
  for _, ws in ipairs(workspaces) do
    workspaceCache[ws] = {}
  end

  -- Parse batch output
  if allWindows and allWindows ~= "" then
    for line in allWindows:gmatch("[^\r\n]+") do
      if line and line ~= "" then
        local ws, windowInfo = line:match("^([^|]+)|(.+)$")
        if ws and windowInfo and workspaceCache[ws] then
          table.insert(workspaceCache[ws], windowInfo)
        end
      end
    end
  end

  lastCacheUpdate = now
end

local function createWorkspaceChoices()
  updateCache()

  local choices = {}
  for i, workspace in ipairs(workspaces) do
    local windows = workspaceCache[workspace] or {}
    local windowText = ""
    if #windows > 0 then
      -- Limit to first 5 windows for cleaner display
      local displayWindows = {}
      for j = 1, math.min(5, #windows) do
        table.insert(displayWindows, windows[j])
      end
      windowText = "\n• " .. table.concat(displayWindows, "\n• ")
      if #windows > 5 then
        windowText = windowText .. "\n• (" .. (#windows - 5) .. " more...)"
      end
    else
      windowText = "\n(empty)"
    end

    table.insert(choices, {
      text = workspace,
      subText = windowText,
      workspace = workspace,
      index = i,
    })
  end
  return choices
end

local function showWorkspaceSwitcher()
  if isVisible then
    return
  end

  updateCurrentWorkspaceIndex()

  chooser = hs.chooser.new(function(choice)
    isVisible = false
    if choice then
      switchToWorkspace(choice.workspace)
    end
  end)

  chooser:choices(createWorkspaceChoices())
  chooser:selectedRow(currentWorkspaceIndex)
  chooser:placeholderText("Select workspace...")
  chooser:width(25)
  chooser:rows(9)
  chooser:show()
  isVisible = true
end

local function hideWorkspaceSwitcher()
  if chooser and isVisible then
    chooser:hide()
    isVisible = false
  end
end

local function nextWorkspace()
  if not isVisible then
    showWorkspaceSwitcher()
    return
  end

  currentWorkspaceIndex = currentWorkspaceIndex % #workspaces + 1
  chooser:selectedRow(currentWorkspaceIndex)
end

local function previousWorkspace()
  if not isVisible then
    showWorkspaceSwitcher()
    return
  end

  currentWorkspaceIndex = currentWorkspaceIndex - 1
  if currentWorkspaceIndex < 1 then
    currentWorkspaceIndex = #workspaces
  end
  chooser:selectedRow(currentWorkspaceIndex)
end

local function selectCurrentWorkspace()
  if chooser and isVisible then
    local selectedRow = chooser:selectedRow()
    if selectedRow then
      local choice = chooser:choices()[selectedRow]
      if choice then
        switchToWorkspace(choice.workspace)
      end
    end
    hideWorkspaceSwitcher()
  end
end

function M.setup()
  -- Alt+Tab for next workspace
  hs.hotkey.bind({ "alt" }, "tab", nextWorkspace, selectCurrentWorkspace, nextWorkspace)

  -- Alt+Shift+Tab for previous workspace
  hs.hotkey.bind(
    { "alt", "shift" },
    "tab",
    previousWorkspace,
    selectCurrentWorkspace,
    previousWorkspace
  )

  -- Escape to cancel
  hs.hotkey.bind({}, "escape", function()
    if isVisible then
      hideWorkspaceSwitcher()
    end
  end)

  -- Hide switcher when modifier keys are released
  local flagWatcher = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(event)
    local flags = event:getFlags()
    if isVisible and not flags.alt then
      selectCurrentWorkspace()
    end
  end)
  flagWatcher:start()
end

return M
