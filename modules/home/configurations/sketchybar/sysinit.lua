local sbar = require("sketchybar")

local username = os.getenv("USER")
local home_dir = "/Users/" .. username

package.path = package.path
  .. ";"
  .. home_dir
  .. "/.config/sketchybar/lua/?.lua"
  .. ";"
  .. home_dir
  .. "/.config/sketchybar/lua/?/init.lua"

require("sysinit.pkg.core").setup()

sbar.add("event", "aerospace_workspace_change")

require("sysinit.pkg.widgets.apple").setup()
require("sysinit.pkg.widgets.front_app").setup()
require("sysinit.pkg.widgets.workspaces").setup()
require("sysinit.pkg.widgets.menu").setup()

require("sysinit.pkg.widgets.system").setup()
require("sysinit.pkg.widgets.volume").setup()

sbar.event_loop()
