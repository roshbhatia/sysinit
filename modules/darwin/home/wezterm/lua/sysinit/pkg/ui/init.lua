local wezterm = require("wezterm")
local act = wezterm.action

local function is_nvim_active()
	return string.match(wezterm.get_foreground_child_process_name() or "", "nvim")
end

local M = {}

function M.setup(config)
	config.window_padding = { left = 20, right = 0, top = 20, bottom = 0 }
	config.enable_scroll_bar = true
	config.enable_tab_bar = true
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

	local function poll_for_nvim(window)
		local overrides = window:get_config_overrides() or {}
		if is_nvim_active() then
			overrides.enable_tab_bar = false
			overrides.font = wezterm.font_with_fallback({
				{
					family = "Monaco",
					weight = "Regular",
				},
				"Symbols Nerd Font",
			})
		else
			overrides.enable_tab_bar = nil
			overrides.font = nil
		end
		window:set_config_overrides(overrides)
	end

	wezterm.on("poll-for-nvim", poll_for_nvim)

	wezterm.on("update-status", function(window, pane)
		window:perform_action(wezterm.action.EmitEvent("poll-for-nvim"), pane)
	end)
end

return M

