local sbar = require("sketchybar")

require("sysinit.pkg.core").setup()

sbar.add("event", "komorebi_workspace_change")
sbar.add("event", "komorebi_mode_changed")

require("sysinit.pkg.widgets.logo").setup()
require("sysinit.pkg.widgets.komorebi_mode").setup()
require("sysinit.pkg.widgets.front_app").setup()
require("sysinit.pkg.widgets.agent_sessions").setup()
require("sysinit.pkg.widgets.workspaces").setup()
require("sysinit.pkg.widgets.menu").setup()

require("sysinit.pkg.widgets.datetime").setup()
require("sysinit.pkg.widgets.battery").setup()
require("sysinit.pkg.widgets.volume").setup()
require("sysinit.pkg.widgets.music").setup()

require("sysinit.pkg.core.health").setup()

sbar.event_loop()
