local wezterm = require("wezterm")

-- Bootstrap package path before loading modules
local home_dir = os.getenv("HOME") or (os.getenv("USER") and "/Users/" .. os.getenv("USER"))
package.path = package.path
  .. ";"
  .. home_dir
  .. "/.config/wezterm/lua/?.lua"
  .. ";"
  .. home_dir
  .. "/.config/wezterm/lua/?/init.lua"

local config = wezterm.config_builder()

require("sysinit.pkg.core").setup(config)
require("sysinit.pkg.keybindings").setup(config)
require("sysinit.pkg.ui").setup(config)
require("sysinit.pkg.resurrect").setup(config)

return config
