local wezterm = require("wezterm")
local M = {}

function M.setup(config)
	config.window_padding = { left = 20, right = 0, top = 20, bottom = 20 }
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
	config.colors = { visual_bell = "#242529" }

	config.font = wezterm.font_with_fallback({
		{
			family = "JetBrains Mono",
			weight = "Light",
			harfbuzz_features = { "zero", "ss01", "liga" },
		},
		"Symbols Nerd Font",
	})
	config.font_size = 14.0
	config.line_height = 1.0

	config.default_cursor_style = "SteadyUnderline"
	config.cursor_blink_rate = 300

	config.enable_tab_bar = true
	config.hide_tab_bar_if_only_one_tab = false
	config.use_fancy_tab_bar = false
	config.tab_bar_at_bottom = true

	wezterm.on("update-status", function(window)
		local color_scheme = window:effective_config().resolved_palette

		local bg = color_scheme.background
		local fg = color_scheme.foreground

		config.set_environment_variables = {
			SYSINIT_COLORSCHEME_BG = bg,
			SYSINIT_COLORSCHEME_FG = fg,
		}

		window:set_right_status(wezterm.format({
			{ Background = { Color = "none" } },
			{ Foreground = { Color = bg } },
			{ Text = utf8.char(0xe0b2) },
			{ Background = { Color = bg } },
			{ Foreground = { Color = fg } },
			{ Text = os.getenv("USER") .. "@" .. wezterm.hostname() .. " 󱄅 " },
		}))
	end)
end

return M
