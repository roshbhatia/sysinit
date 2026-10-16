local sbar = require("sketchybar")
local M = {}

function M.setup()
  local heartbeat = sbar.add("item", "sysinit_health", {
    drawing = false,
    updates = "on",
    update_freq = 10,
    label = tostring(os.time()),
  })
  heartbeat:subscribe({ "routine", "system_woke" }, function()
    heartbeat:set({ label = tostring(os.time()) })
  end)
end

return M
