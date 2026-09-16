local M = {}
local timer
local key = "sysinit.hiddenAppsBoot"

function M.setup()
  local boot, ok = hs.execute("/usr/sbin/sysctl -n kern.bootsessionuuid")
  if not ok then
    hs.printf("Cannot read boot session; startup hiding skipped")
    return
  end
  boot = boot:match("%S+")
  if not boot or hs.settings.get(key) == boot then
    return
  end
  if not hs.settings.get(key) then
    hs.settings.set(key, boot)
    return
  end
  if timer then
    timer:stop()
  end
  timer = hs.timer.doAfter(15, function()
    for _, app in ipairs(hs.application.runningApplications()) do
      if app:kind() == 1 and not app:isHidden() then
        app:hide()
      end
    end
    hs.settings.set(key, boot)
    timer = nil
  end)
end

return M
