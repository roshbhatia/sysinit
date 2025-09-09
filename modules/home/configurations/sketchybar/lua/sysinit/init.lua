local sbar = require("sketchybar")

require("sysinit.pkg.core").setup()

sbar.add("event", "aerospace_workspace_change")

require("sysinit.pkg.widgets.apple").setup()
require("sysinit.pkg.widgets.front_app").setup()
require("sysinit.pkg.widgets.workspaces").setup()
require("sysinit.pkg.widgets.menu").setup()

require("sysinit.pkg.widgets.system").setup()
require("sysinit.pkg.widgets.volume").setup()

sbar.event_loop()
