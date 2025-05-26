local wezterm = require("wezterm")

local function is_nvim_active()
	return string.match(wezterm.get_foreground_child_process_name() or "", "nvim")
end

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
	config.color_scheme = "Rosé Pine (Gogh)"

	-- Default font
	config.font = wezterm.font_with_fallback({
		{
			family = "JetBrains Mono",
			weight = "Medium",
			harfbuzz_features = { "zero" },
		},
		"Symbols Nerd Font",
	})
	config.font_size = 14.0
	config.line_height = 1.0
	config.default_cursor_style = "SteadyUnderline"
	config.cursor_blink_rate = 300

	wezterm.on("update-status", function(window, pane)
		if is_nvim_active() then
			window:set_config_overrides({
				enable_tab_bar = false,
				font = wezterm.font_with_fallback({
					{
						family = "Monaco",
						weight = "Regular",
					},
					"Symbols Nerd Font",
				}),
			})
		else
			window:set_config_overrides({
				enable_tab_bar = true,
				font = wezterm.font_with_fallback({
					{
						family = "JetBrains Mono",
						weight = "Medium",
						harfbuzz_features = { "zero" },
					},
					"Symbols Nerd Font",
				}),
			})
		end
	end)

	-- GUI startup handler
	wezterm.on("gui-startup", function(cmd)
		local screen = wezterm.gui.screens().active
		if not screen then
			return
		end
		local _, _, window = wezterm.mux.spawn_window(cmd or {})
		local gui_window = window:gui_window()
		if gui_window then
			gui_window:set_position(screen.x, screen.y)
			gui_window:set_inner_size(screen.width - 2, screen.height - 2)
		end
	end)

	-- Include the external bar plugin
	local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
	workspace_switcher.apply_to_config(config)
end

return M

