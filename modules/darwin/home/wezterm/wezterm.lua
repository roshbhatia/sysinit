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

-- local bar = wezterm.plugin.require("file://" .. home_dir .. "/.config/wezterm/plugins/bar.wezterm")
local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")
bar.apply_to_config(config, {
	padding = {
		left = 2,
		right = 2,
		tabs = {
			left = 0,
			right = 2,
		},
	},
	modules = {
		workspace = {
			enabled = false,
		},
		leader = {
			enabled = false,
		},
		clock = {
			enabled = false,
		},
		pane = {
			enabled = false,
		},
	},
})

config.set_environment_variables = {
	TERM = "wezterm",
}

return config

