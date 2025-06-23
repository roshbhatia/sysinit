local wezterm = require("wezterm")
local toggle_terminal = wezterm.plugin.require("https://github.com/zsh-sage/toggle_terminal.wez")

local M = {}

function M.setup(config)
	toggle_terminal.apply_to_config(config, {
		key = "\\",
		mods = "CTRL",
		direction = "Right",
		size = { Percent = 30 },
		change_invoker_id_everytime = false,
		zoom = {
			auto_zoom_toggle_terminal = true,
			auto_zoom_invoker_pane = true,
			remember_zoomed = true,
		},
	})

	return config
end

return M

