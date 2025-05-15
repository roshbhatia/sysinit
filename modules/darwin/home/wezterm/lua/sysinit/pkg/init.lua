local wezterm = require("wezterm")
local config = wezterm.config_builder()
local username = os.getenv("USER")

require("sysinit.pkg.wezterm.ui").setup(config)
require("sysinit.pkg.wezterm.theme").setup(config)
require("sysinit.pkg.wezterm.keybinds").setup(config)

config.default_prog = { string.format("/etc/profiles/per-user/%s/bin/zsh", username), "-l" }
config.set_environment_variables = {
	SHELL = string.format("/etc/profiles/per-user/%s/bin/zsh", username),
	TERM = "wezterm",
}

return config
