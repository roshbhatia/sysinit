local M = {}

local workspaces = { "1", "2", "3", "4", "C", "E", "M", "S", "X" }
local currentWorkspaceIndex = 1
local isVisible = false
local chooser = nil
local workspaceCache = {}
local cacheExpiry = 1
local lastCacheUpdate = 0

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

local function updateCache()
  local now = hs.timer.secondsSinceEpoch()
  if now - lastCacheUpdate < cacheExpiry then
    return
  end

  local all = hs.execute(
    "aerospace list-windows --all --format '%{workspace}|%{app-name}: %{window-title}'",
    true
  )
  workspaceCache = {}
  for _, w in ipairs(workspaces) do
    workspaceCache[w] = {}
  end

  if all then
    for line in all:gmatch("[^\r\n]+") do
      local ws, info = line:match("^([^|]+)|(.+)$")
      if ws and info and workspaceCache[ws] then
        table.insert(workspaceCache[ws], info)
      end
    end
  end

  lastCacheUpdate = now
end

local function createWorkspaceChoices()
  updateCache()
  local choices = {}

  for i, ws in ipairs(workspaces) do
    local windows = workspaceCache[ws] or {}
    local preview = #windows > 0 and ("• " .. table.concat(windows, "\n• ")) or "(empty)"
    if #windows > 5 then
      preview = "• "
        .. table.concat(windows, "\n• ", 1, 5)
        .. "\n• ("
        .. (#windows - 5)
        .. " more...)"
    end

    table.insert(choices, {
      text = "Workspace " .. ws,
      subText = preview,
      workspace = ws,
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
  chooser:width(40)
  chooser:rows(9)
  chooser:searchSubText(false)
  chooser:bgDark(true)
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

  currentWorkspaceIndex = (currentWorkspaceIndex - 2) % #workspaces + 1
  chooser:selectedRow(currentWorkspaceIndex)
end

local function selectCurrentWorkspace()
  if chooser and isVisible then
    local selectedRow = chooser:selectedRow()
    local choice = chooser:choices()[selectedRow]
    if choice then
      switchToWorkspace(choice.workspace)
    end
    hideWorkspaceSwitcher()
  end
end

function M.setup()
  hs.hotkey.bind({ "alt" }, "tab", nextWorkspace, selectCurrentWorkspace, nextWorkspace)
  hs.hotkey.bind(
    { "alt", "shift" },
    "tab",
    previousWorkspace,
    selectCurrentWorkspace,
    previousWorkspace
  )

  -- Cancel switcher on Escape
  hs.eventtap
    .new({ hs.eventtap.event.types.keyDown }, function(event)
      if isVisible and event:getKeyCode() == hs.keycodes.map.escape then
        hideWorkspaceSwitcher()
        return true
      end
      return false
    end)
    :start()

  -- Confirm workspace selection on Alt key release
  hs.eventtap
    .new({ hs.eventtap.event.types.flagsChanged }, function(event)
      if isVisible and not event:getFlags().alt then
        selectCurrentWorkspace()
      end
    end)
    :start()
end

return M

