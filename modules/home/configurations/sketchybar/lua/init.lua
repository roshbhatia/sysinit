local sbar = require("sketchybar")

local core = require("sysinit.pkg.core")
local apple = require("sysinit.pkg.items.apple")
local menu = require("sysinit.pkg.items.menu")
local front_app = require("sysinit.pkg.items.front_app")
local workspaces = require("sysinit.pkg.items.workspaces")
local volume = require("sysinit.pkg.items.volume")
local system = require("sysinit.pkg.items.system")

core.setup()

sbar.add("event", "aerospace_workspace_change")

apple.setup()
menu.setup()
front_app.setup()
workspaces.setup()
volume.setup()
system.setup()

sbar.event_loop()
