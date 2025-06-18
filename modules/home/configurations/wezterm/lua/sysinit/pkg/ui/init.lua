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
		window_background_opacity = 0.75,
		macos_window_background_blur = 80,
		window_decorations = "RESIZE",
	}
end

local function get_display_config()
	return {
		enable_tab_bar = true,
		max_fps = 240,
		color_scheme = terminal_theme,
		scrollback_lines = 20000,
		adjust_window_size_when_changing_font_size = false,
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

local function setup_nvim_ui_overrides()
	wezterm.on("update-status", function(window, pane)
		local should_switch = is_vim(pane)
		local overrides = window:get_config_overrides() or {}
		if should_switch then
			overrides.window_padding = {
				left = "8px",
				top = "8px",
				bottom = "0px",
			}
			overrides.window_background_opacity = 0.92
		else
			overrides.window_padding = nil
			overrides.window_background_opacity = nil
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

	setup_nvim_ui_overrides()

	return config
end

return M
