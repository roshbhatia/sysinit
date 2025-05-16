local wezterm = require("wezterm")

local username = os.getenv("USER")
local home_dir = "/Users/" .. username

package.path = package.path .. ";" .. home_dir .. "/.config/lua/?.lua"

local config = wezterm.config_builder()

require("sysinit.pkg.ui").setup(config)
require("sysinit.pkg.theme").setup(config)
require("sysinit.pkg.keybindings").setup(config)

config.set_environment_variables = {
	TERM = "wezterm",
}

return config
