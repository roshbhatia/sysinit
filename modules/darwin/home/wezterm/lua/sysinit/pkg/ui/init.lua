local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

function M.setup(config)
	config.window_padding = { left = 20, right = 0, top = 20, bottom = 0 }
	config.enable_scroll_bar = true
	config.scrollback_lines = 20000
	config.window_background_opacity = 0.9
	config.macos_window_background_blur = 70
	config.window_decorations = "RESIZE"
	config.visual_bell = {
		fade_in_function = "EaseIn",
		fade_in_duration_ms = 35,
		fade_out_function = "EaseOut",
		fade_out_duration_ms = 50,
	}
	config.color_scheme = "rose-pine"
	config.font = wezterm.font_with_fallback({
		{
			family = "Hack Nerd Font Mono",
			harfbuzz_features = { "zero", "ss01", "liga" },
		},
		"Symbols Nerd Font",
	})
	config.font_size = 12.0
	config.line_height = 1.0
	config.default_cursor_style = "SteadyUnderline"
	config.cursor_blink_rate = 300
	wezterm.on("gui-startup", function(cmd)
		local screen = wezterm.gui.screens().active
		if not screen then
			return
		end
		local _, _, window = wezterm.mux.spawn_window(cmd or {})
		local gui_window = window:gui_window()
		if gui_window then
			gui_window:set_position(screen.x, screen.y)
			gui_window:set_inner_size(screen.width, screen.height)
		end
	end)
end

return M
