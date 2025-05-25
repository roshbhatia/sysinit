local wezterm = require("wezterm")

local username = os.getenv("USER")
local home_dir = "/Users/" .. username

package.path = package.path
	.. ";"
	.. home_dir
	.. "/.config/wezterm/lua/?.lua"
	.. ";"
	.. home_dir
	.. "/.config/wezterm/lua/?/init.lua"

local config = wezterm.config_builder()

require("sysinit.pkg.keybindings").setup(config)
require("sysinit.pkg.ui").setup(config)

require("sysinit.plugins.ui.bar").setup(config)
require("sysinit.plugins.ui.session").setup(config)

config.set_environment_variables = {
	TERM = "wezterm",
}

return config

