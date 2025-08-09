local M = {}

local function nextWorkspace()
  hs.execute("aerospace workspace next", true)
end

local function previousWorkspace()
  hs.execute("aerospace workspace prev", true)
end

function M.setup()
  -- Alt+Tab for next workspace, Alt+Shift+Tab for previous
  hs.hotkey.bind({ "alt" }, "tab", nextWorkspace)
  hs.hotkey.bind({ "alt", "shift" }, "tab", previousWorkspace)
end

return M
