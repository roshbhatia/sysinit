local wezterm = require("wezterm")
local M = {}

local terminal_theme = "Rosé Pine Moon (Gogh)"
local nvim_theme = "nordfox"

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

local nvim_font = wezterm.font_with_fallback({
	{
		family = "Monaspace Neon",
		harfbuzz_features = {
			"calt",
			"zero",
			"ss01",
			"cv01",
		},
	},
	"Symbols Nerd Font",
})

local function is_vim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

local function get_window_padding_config()
	return {
		window_padding = {
			left = "8px",
			top = "8px",
		},
	}
end

local function get_window_appearance_config()
	return {
		window_background_opacity = 0.7,
		macos_window_background_blur = 75,
		window_decorations = "RESIZE",
	}
end

local function get_display_config()
	return {
		enable_scroll_bar = true,
		enable_tab_bar = true,
		text_min_contrast_ratio = 4.5,
		max_fps = 144,
		color_scheme = terminal_theme,
		scrollback_lines = 20000,
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

local function setup_gui_startup()
	wezterm.on("gui-startup", function(cmd)
		local screen = wezterm.gui.screens().active
		if not screen then
			return
		end

		local _, _, window = wezterm.mux.spawn_window(cmd or {})
		local padding = 25
		local adjusted_width = screen.width - (2 * padding)
		local adjusted_height = screen.height - (2 * padding)

		local gui_window = window:gui_window()
		if gui_window then
			gui_window:set_position(screen.x, screen.y)
			gui_window:set_inner_size(adjusted_width, adjusted_height)
		end
	end)
end

local function setup_nvim_ui_overrides()
	wezterm.on("update-status", function(window, pane)
		local should_switch = is_vim(pane)
		local overrides = window:get_config_overrides() or {}
		if should_switch then
			overrides.color_scheme = nvim_theme
			overrides.font = nvim_font
			overrides.enable_scroll_bar = false
			overrides.window_background_opacity = 0.865
			overrides.window_padding = {
				left = "8px",
				top = "8px",
				bottom = "0px",
			}
		else
			overrides.color_scheme = nil
			overrides.font = nil
			overrides.enable_scroll_bar = nil
			overrides.window_background_opacity = nil
			overrides.window_padding = nil
		end
		window:set_config_overrides(overrides)
	end)
end

function M.setup(config)
	local configs = {
		get_window_padding_config(),
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

	setup_gui_startup()
	setup_nvim_ui_overrides()

	return config
end

return M
