local sbar = require("sketchybar")

local core = require("sysinit.pkg.core")
local front_app = require("sysinit.pkg.items.front_app")
local workspaces = require("sysinit.pkg.items.workspaces")
local system = require("sysinit.pkg.items.system")

core.setup()

sbar.add("event", "aerospace_workspace_change")

front_app.setup()
workspaces.setup()
system.setup()

sbar.event_loop()
