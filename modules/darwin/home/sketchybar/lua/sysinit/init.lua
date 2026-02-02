local sbar = require("sketchybar")

require("sysinit.pkg.core").setup()

sbar.add("event", "aerospace_workspace_change")
sbar.add("event", "aerospace_mode_changed")

require("sysinit.pkg.widgets.logo").setup()
require("sysinit.pkg.widgets.aerospace_mode").setup()
require("sysinit.pkg.widgets.front_app").setup()
require("sysinit.pkg.widgets.music").setup()
require("sysinit.pkg.widgets.workspaces").setup()
require("sysinit.pkg.widgets.menu").setup()

require("sysinit.pkg.widgets.datetime").setup()
require("sysinit.pkg.widgets.battery").setup()
require("sysinit.pkg.widgets.volume").setup()

sbar.event_loop()
