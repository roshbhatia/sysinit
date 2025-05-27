local wezterm = require("wezterm")

local M = {}

function M.setup(config)
	config.status_update_interval = 50
	config.window_padding = { left = 20, right = 0, top = 20, bottom = 0 }
	config.enable_scroll_bar = true
	config.enable_tab_bar = true
	config.tab_bar_at_bottom = true
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
	config.color_scheme = "Rosé Pine (Gogh)"

	config.font = wezterm.font_with_fallback({
		{
			family = "Fira Mono for Powerline",
			weight = "Medium",
			harfbuzz_features = { "zero" },
		},
		"Symbols Nerd Font",
	})
	config.font_size = 14.0
	config.line_height = 1.0
	config.default_cursor_style = "SteadyUnderline"
	config.cursor_blink_rate = 300

	wezterm.on("gui-startup", function(cmd)
		local active = wezterm.gui.screens().active
		local _, _, window = wezterm.mux.spawn_window(cmd or {})

		local padding = 12 -- Define the 12px padding
		local screen_width = active.width
		local screen_height = active.height

		local adjusted_width = screen_width - (2 * padding)
		local adjusted_height = screen_height - (2 * padding)

		window:guiwindow():setposition(active.x + padding, active.y + padding)
		window:guiwindow():set_innersize(adjusted_width, adjusted_height)
	end)
end

return M
