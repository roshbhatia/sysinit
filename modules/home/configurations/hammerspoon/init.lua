local home_dir = os.getenv("HOME")

package.path = package.path
  .. ";"
  .. home_dir
  .. "/.hammerspoon/lua/?.lua"
  .. ";"
  .. home_dir
  .. "/.hammerspoon/lua/?/init.lua"

require("sysinit.pkg.theme")
require("sysinit.pkg.core").setup()
require("sysinit.plugins.ui.vim-mode").setup()
require("sysinit.plugins.window.aerospace-switcher").setup()
