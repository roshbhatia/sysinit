local sbar = require("sketchybar")

-- Load modules
local core = require("sysinit.pkg.core")
local front_app = require("sysinit.pkg.items.front_app")
local workspaces = require("sysinit.pkg.items.workspaces")
local system = require("sysinit.pkg.items.system")

-- Setup core bar configuration
core.setup()

-- Register aerospace workspace change event
sbar.add("event", "aerospace_workspace_change")

-- Setup items
front_app.setup()
workspaces.setup()
system.setup()

-- Start event loop
sbar.event_loop()
