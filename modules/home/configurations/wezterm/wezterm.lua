local wezterm = require("wezterm")

local home_dir = os.getenv("HOME")
if not home_dir then
  local username = os.getenv("USER")
  home_dir = "/Users/" .. username
end

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
require("sysinit.pkg.theme").setup(config)
require("sysinit.pkg.ui").setup(config)

return config
