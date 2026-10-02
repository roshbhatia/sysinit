local home_dir = os.getenv("HOME")

package.path = package.path
  .. ";"
  .. home_dir
  .. "/.hammerspoon/lua/?.lua"
  .. ";"
  .. home_dir
  .. "/.hammerspoon/lua/?/init.lua"

require("hs.ipc")

require("sysinit.pkg.url_routing").setup()

require("sysinit.pkg.theme")

local function bindHotkeys()
  require("sysinit.pkg.core").setup()
  require("sysinit.pkg.core.startup").setup()
  require("sysinit.plugins.ui.screenshots").setup()
  require("sysinit.plugins.ui.launcher").setup()
end

if hs.accessibilityState() then
  bindHotkeys()
else
  local waitForAccessibility
  waitForAccessibility = hs.timer.doEvery(2, function()
    if hs.accessibilityState() then
      waitForAccessibility:stop()
      bindHotkeys()
    end
  end)
end
