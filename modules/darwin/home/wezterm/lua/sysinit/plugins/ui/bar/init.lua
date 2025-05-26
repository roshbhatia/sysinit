local wezterm = require("wezterm")
local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")
local M = {}

function M.setup(config)
	bar.apply_to_config(config, {
		padding = {
			left = 6,
			right = 6,
			tabs = {
				left = 0,
				right = 2,
			},
		},
		modules = {
			hostname = {
				enabled = false,
			},
			workspace = {
				enabled = false,
			},
			leader = {
				enabled = false,
			},
			clock = {
				enabled = false,
			},
			username = {
				enabled = false,
			},
		},
	})
end

return M

