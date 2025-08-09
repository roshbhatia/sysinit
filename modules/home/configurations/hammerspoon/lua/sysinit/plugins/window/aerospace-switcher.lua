local M = {}

-- Use the correct aerospace binary path
local AEROSPACE_BIN = "/run/current-system/sw/bin/aerospace"

local function nextWorkspace()
  -- Use hs.task for async execution - much faster than hs.execute
  hs.task.new(AEROSPACE_BIN, nil, nil, {"workspace", "--wrap-around", "next"}):start()
end

local function previousWorkspace()
  -- Use hs.task for async execution - much faster than hs.execute
  hs.task.new(AEROSPACE_BIN, nil, nil, {"workspace", "--wrap-around", "prev"}):start()
end

function M.setup()
  -- Alt+Tab for next workspace, Alt+Shift+Tab for previous
  hs.hotkey.bind({ "alt" }, "tab", nextWorkspace)
  hs.hotkey.bind({ "alt", "shift" }, "tab", previousWorkspace)
end

return M

