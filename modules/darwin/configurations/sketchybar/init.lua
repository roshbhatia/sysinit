local home_dir = os.getenv("HOME")
local user = os.getenv("USER")

package.path = package.path
  .. ";"
  .. home_dir
  .. "/.config/sketchybar/lua/?.lua"
  .. ";"
  .. home_dir
  .. "/.config/sketchybar/lua/?/init.lua"

package.cpath = package.cpath .. ";" .. home_dir .. "/.local/share/sketchybar_lua/?.so"

require("sysinit.pkg.theme")
require("sysinit.pkg.core").setup()
require("sysinit.pkg.items.workspaces").setup()
require("sysinit.pkg.items.front_app").setup()
require("sysinit.pkg.items.system").setup()
