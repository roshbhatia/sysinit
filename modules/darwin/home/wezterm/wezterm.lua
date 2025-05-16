package.path = package.path
	.. ";"
	.. vim.fn.stdpath("config")
	.. "/?.lua"
	.. ";"
	.. vim.fn.stdpath("config")
	.. "/lua/?.lua"

local wezterm = require("wezterm")
local config = wezterm.config_builder()
local username = os.getenv("USER")

require("sysinit.pkg.wezterm.ui").setup(config)
require("sysinit.pkg.wezterm.theme").setup(config)
require("sysinit.pkg.wezterm.keybinds").setup(config)

config.set_environment_variables = {
	TERM = "wezterm",
}

return config
