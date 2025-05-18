local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local function ensure_cache_exists()
	local username = os.getenv("USER")
	local cache_dir = "/Users/" .. username .. "/.cache/wezterm"
	local theme_file = cache_dir .. "/theme"

	local success, _, code = os.execute("mkdir -p " .. cache_dir)
	if not success or code ~= 0 then
		wezterm.log_error("Failed to create cache directory: " .. cache_dir)
	end

	local file = io.open(theme_file, "r")
	if not file then
		file = io.open(theme_file, "w")
		if file then
			file:write("rose-pine")
			file:close()
		else
			wezterm.log_error("Failed to create theme file: " .. theme_file)
		end
	else
		file:close()
	end
end

local function get_theme()
	local username = os.getenv("USER")
	local theme_file = "/Users/" .. username .. "/.cache/wezterm/theme"
	local success, data = pcall(wezterm.read_file, theme_file)
	return success and data or "rose-pine"
end

function M.setup(config)
	ensure_cache_exists()

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
	config.color_scheme = get_theme()
	config.font = wezterm.font_with_fallback({
		{
			family = "JetBrains Mono",
			weight = "Light",
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

