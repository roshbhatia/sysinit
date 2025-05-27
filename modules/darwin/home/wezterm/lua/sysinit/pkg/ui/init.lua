local wezterm = require("wezterm")
local M = {}

local themes = {
	"Rosé Pine (Gogh)",
	"Rosé Pine Moon (Gogh)",
	"Catppuccin Frappé (Gogh)",
	"Catppuccin Macchiato (Gogh)",
	"Nord (base16)",
	"DoomOne",
	"nordfox",
	"Relaxed",
}

local fonts = {
	{
		name = "Intel One Mono",
		family = "Intel One Mono",
		weight = "Regular",
		features = { "ss01", "ss02", "ss03", "ss11", "ccmp", "mark", "aalt" },
	},
	{
		name = "Fira Mono for Powerline",
		family = "Fira Mono for Powerline",
		weight = "Medium",
		features = { "zero" },
	},
	{
		name = "MonoFur for Powerline",
		family = "MonoFur for Powerline",
		weight = "Regular",
		features = {},
	},
	{
		name = "Hack Nerd Font Mono",
		family = "Hack Nerd Font Mono",
		weight = "Regular",
		features = {},
	},
	{
		name = "JetBrains Mono",
		family = "JetBrains Mono",
		weight = "Regular",
		features = {},
	},
	{
		name = "Geist Mono",
		family = "Geist Mono",
		weight = "Regular",
		features = {},
	},
	{
		name = "Noto Mono for Powerline",
		family = "Noto Mono for Powerline",
		weight = "Regular",
		features = {},
	},
}

local current_theme_index = 1
local current_font_index = 1

local function get_basic_config()
	return {
		window_padding = { left = 16, right = 0, top = 16, bottom = 0 },
		enable_scroll_bar = true,
		enable_tab_bar = true,
		scrollback_lines = 20000,
		window_background_opacity = 0.9,
		macos_window_background_blur = 70,
		window_decorations = "RESIZE",
	}
end

local function get_visual_bell_config()
	return {
		fade_in_function = "EaseIn",
		fade_in_duration_ms = 35,
		fade_out_function = "EaseOut",
		fade_out_duration_ms = 50,
	}
end

local function get_font_config()
	local font_config = fonts[current_font_index]
	return wezterm.font_with_fallback({
		{
			family = font_config.family,
			weight = font_config.weight,
			harfbuzz_features = font_config.features,
		},
		"Symbols Nerd Font",
	})
end

local function get_cursor_config()
	return {
		font_size = 14.0,
		line_height = 1.0,
		default_cursor_style = "SteadyUnderline",
		cursor_blink_rate = 300,
	}
end

local function cycle_theme()
	current_theme_index = current_theme_index % #themes + 1
	return themes[current_theme_index]
end

local function cycle_font()
	current_font_index = current_font_index % #fonts + 1
	return get_font_config()
end

local function get_theme_font_keys()
	return {
		{
			key = "t",
			mods = "CMD|SHIFT",
			action = wezterm.action_callback(function(window, pane)
				local overrides = window:get_config_overrides() or {}
				overrides.color_scheme = cycle_theme()
				window:set_config_overrides(overrides)
			end),
		},
		{
			key = "f",
			mods = "CMD|SHIFT",
			action = wezterm.action_callback(function(window, pane)
				local overrides = window:get_config_overrides() or {}
				overrides.font = cycle_font()
				window:set_config_overrides(overrides)
			end),
		},
	}
end

local function setup_gui_startup()
	wezterm.on("gui-startup", function(cmd)
		local screen = wezterm.gui.screens().active
		if not screen then
			return
		end

		local _, _, window = wezterm.mux.spawn_window(cmd or {})

		local padding = 12
		local adjusted_width = screen.width - (2 * padding)
		local adjusted_height = screen.height - (2 * padding)

		local gui_window = window:gui_window()
		if gui_window then
			gui_window:set_position(screen.x + padding, screen.y + padding)
			gui_window:set_inner_size(adjusted_width, adjusted_height)
		end
	end)
end

function M.setup(config)
	local basic_config = get_basic_config()
	for key, value in pairs(basic_config) do
		config[key] = value
	end

	config.visual_bell = get_visual_bell_config()
	config.color_scheme = themes[current_theme_index]
	config.font = get_font_config()

	local cursor_config = get_cursor_config()
	for key, value in pairs(cursor_config) do
		config[key] = value
	end

	local theme_font_keys = get_theme_font_keys()
	config.keys = config.keys or {}
	for _, key_binding in ipairs(theme_font_keys) do
		table.insert(config.keys, key_binding)
	end

	setup_gui_startup()

	return config
end

return M

