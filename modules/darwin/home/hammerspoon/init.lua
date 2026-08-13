local home_dir = os.getenv("HOME")

package.path = package.path
  .. ";"
  .. home_dir
  .. "/.hammerspoon/lua/?.lua"
  .. ";"
  .. home_dir
  .. "/.hammerspoon/lua/?/init.lua"

-- The message port the `hs` CLI talks to. Loaded so the launcher can be opened from
-- outside Hammerspoon, by a WezTerm key or by a shell.
require("hs.ipc")

require("sysinit.pkg.theme")
require("sysinit.pkg.core").setup()
require("sysinit.plugins.ui.vim-mode").setup()
require("sysinit.plugins.ui.launcher").setup()
