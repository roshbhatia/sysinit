local M = {}

local apps = function()
  local running = hs.application.runningApplications()
  local filtered = {}
  for _, app in ipairs(running) do
    if app:kind() == 1 and not app:isHidden() and app:name() ~= "Hammerspoon" then
      table.insert(filtered, app)
    end
  end
  return filtered
end

local switch = function()
  local appList = apps()
  table.sort(appList, function(a, b)
    return a:pid() < b:pid()
  end)
  local front = hs.application.frontmostApplication()
  local idx = 1
  for i, app in ipairs(appList) do
    if app == front then
      idx = i
      break
    end
  end
  local nextIdx = idx % #appList + 1
  appList[nextIdx]:activate()
end

function M.setup()
  hs.hotkey.bind({ "cmd" }, "tab", switch, nil, switch)
end

return M
