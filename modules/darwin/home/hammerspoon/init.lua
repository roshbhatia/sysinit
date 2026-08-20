local home_dir = os.getenv("HOME")

package.path = package.path
  .. ";"
  .. home_dir
  .. "/.hammerspoon/lua/?.lua"
  .. ";"
  .. home_dir
  .. "/.hammerspoon/lua/?/init.lua"

require("hs.ipc")

require("sysinit.pkg.theme")

local function bindHotkeys()
  require("sysinit.pkg.core").setup()
  require("sysinit.plugins.ui.launcher").setup()
end

-- Post-reboot, Accessibility can grant a beat after Hammerspoon launches; a
-- bind attempted before that grant silently registers no hotkeys and never
-- retries. Poll until granted, then bind exactly once, so this never double-binds.
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
