local wezterm = require("wezterm")
local M = {}

local terminal_theme = "Catppuccin Frappé (Gogh)"

local terminal_font = wezterm.font_with_fallback({
	{
		family = "JetBrains Mono",
		weight = "Regular",
		harfbuzz_features = {
			"calt",
			"zero",
		},
	},
	"Symbols Nerd Font",
})

local function is_vim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

local function get_window_appearance_config()
	return {
		window_background_opacity = 0.8,
		macos_window_background_blur = 80,
		window_decorations = "RESIZE",
	}
end

local function get_display_config()
	return {
		enable_tab_bar = true,
		max_fps = 240,
		animation_fps = 240,
		color_scheme = terminal_theme,
		scrollback_lines = 20000,
		adjust_window_size_when_changing_font_size = false,
		tab_bar_at_bottom = true,
		use_fancy_tab_bar = false,
	}
end

local function get_visual_bell_config()
	return {
		fade_in_function = "EaseIn",
		fade_in_duration_ms = 70,
		fade_out_function = "EaseOut",
		fade_out_duration_ms = 100,
	}
end

local function get_font_config()
	return {
		font = terminal_font,
		freetype_load_target = "Light",
		font_size = 13.0,
		line_height = 1.0,
	}
end

local function get_cursor_config()
	return {
		default_cursor_style = "SteadyUnderline",
		cursor_blink_rate = 300,
	}
end

function M.setup(config)
	local configs = {
		get_window_appearance_config(),
		get_display_config(),
		get_cursor_config(),
		get_font_config(),
	}

	for _, cfg in ipairs(configs) do
		for key, value in pairs(cfg) do
			config[key] = value
		end
	end

	config.visual_bell = get_visual_bell_config()
end

return M
