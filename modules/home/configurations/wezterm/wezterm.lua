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

local theme = "Catppuccin Frappé (Gogh)"
require("sysinit.pkg.core").setup(config)
require("sysinit.pkg.keybindings").setup(config)
require("sysinit.pkg.ui").setup(config, theme)

require("sysinit.plugins.ui.tabline").setup(theme)
require("sysinit.plugins.file.session").setup(config)
require("sysinit.plugins.terminal.toggle").setup(config)

return config

