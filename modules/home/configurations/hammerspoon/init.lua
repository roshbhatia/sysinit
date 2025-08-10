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
require("sysinit.plugins.ui.theme-switcher").setup({
  mods = { "cmd", "alt" },
  show_chooser_key = "t",
  next_theme_key = "n",
  prev_theme_key = "p",
  current_theme_key = "c",
})
