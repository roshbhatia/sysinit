local wezterm = require("wezterm")
local M = {}

local function is_vim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

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

local font_shared_features = {
	"calt",
	"zero",
}

local terminal_font = wezterm.font_with_fallback({
	{
		name = "JetBrains Mono",
		family = "JetBrains Mono",
		weight = "Regular",
		features = font_shared_features,
	},
	"Symbols Nerd Font",
})

local nvim_font = wezterm.font_with_fallback({
	{
		name = "Intel One Mono",
		family = "Intel One Mono",
		weight = "Regular",
		features = font_shared_features,
	},
	"Symbols Nerd Font",
})

local current_theme_index = 1

local function get_basic_config()
	return {
		window_padding = {
			left = "8px",
			top = "8px",
		},
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
	return {
		font = terminal_font,
		font_size = 12.0,
		line_height = 1.0,
	}
end

local function get_cursor_config()
	return {
		default_cursor_style = "SteadyUnderline",
		cursor_blink_rate = 300,
	}
end

local function cycle_theme()
	current_theme_index = current_theme_index % #themes + 1
	return themes[current_theme_index]
end

local function get_theme_keys()
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
			gui_window:set_position(screen.x, screen.y)
			gui_window:set_inner_size(adjusted_width, adjusted_height)
		end
	end)
end

local function setup_nvim_font_switch()
	wezterm.on("update-status", function(window, pane)
		local should_swtich = is_vim(pane)
		local overrides = window:get_config_overrides() or {}
		if should_swtich then
			overrides.font = nvim_font
			overrides.font_size = 14.0
		else
			overrides.font = nil
			overrides.font_size = nil
		end
		window:set_config_overrides(overrides)
	end)
end

function M.setup(config)
	local basic_config = get_basic_config()
	for key, value in pairs(basic_config) do
		config[key] = value
	end

	config.visual_bell = get_visual_bell_config()
	config.color_scheme = themes[current_theme_index]
	config.font = terminal_font

	local cursor_config = get_cursor_config()
	for key, value in pairs(cursor_config) do
		config[key] = value
	end

	local font_config = get_font_config()
	for key, value in pairs(font_config) do
		config[key] = value
	end

	local theme_keys = get_theme_keys()
	config.keys = config.keys or {}
	for _, key_binding in ipairs(theme_keys) do
		table.insert(config.keys, key_binding)
	end

	setup_gui_startup()
	setup_nvim_font_switch()

	return config
end

return M

