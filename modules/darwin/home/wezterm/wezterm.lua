local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()
local username = os.getenv("USER")

local function is_vim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

local direction_keys = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

local function setup_shell(config)
	config.default_prog = { string.format("/etc/profiles/per-user/%s/bin/zsh", username), "-l" }
	config.set_environment_variables = {
		SHELL = string.format("/etc/profiles/per-user/%s/bin/zsh", username),
		TERM = "wezterm",
	}
	return config
end

local function setup_window(config)
	config.window_padding = {
		left = 20,
		right = 0,
		top = 20,
		bottom = 20,
	}
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
	config.colors = {
		visual_bell = "#242529",
	}

	config.color_scheme = "Catppuccin Macchiato (Gogh)"

	return config
end

local function setup_font(config)
	config.font = wezterm.font_with_fallback({
		{
			family = "JetBrains Mono",
			weight = "Medium",
			harfbuzz_features = { "zero", "ss01", "liga" },
		},
		"Symbols Nerd Font",
	})
	config.font_size = 12.0
	config.line_height = 1.0

	return config
end

local function setup_cursor_and_tabs(config)
	config.default_cursor_style = "SteadyUnderline"
	config.cursor_blink_rate = 300

	config.enable_tab_bar = true
	config.hide_tab_bar_if_only_one_tab = false
	config.use_fancy_tab_bar = false

	return config
end

local function split_nav(resize_or_move, key)
	return {
		key = key,
		mods = resize_or_move == "resize" and "META" or "CTRL",
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				win:perform_action({
					SendKey = {
						key = key,
						mods = resize_or_move == "resize" and "META" or "CTRL",
					},
				}, pane)
			else
				if resize_or_move == "resize" then
					win:perform_action({
						AdjustPaneSize = { direction_keys[key], 3 },
					}, pane)
				else
					win:perform_action({
						ActivatePaneDirection = direction_keys[key],
					}, pane)
				end
			end
		end),
	}
end

local function generate_smart_splits_keys()
	return {
		split_nav("move", "h"),
		split_nav("move", "j"),
		split_nav("move", "k"),
		split_nav("move", "l"),
		split_nav("resize", "h"),
		split_nav("resize", "j"),
		split_nav("resize", "k"),
		split_nav("resize", "l"),
	}
end

local function setup_base_keybindings()
	return {
		{
			key = "v",
			mods = "CMD|SHIFT",
			action = act.SplitHorizontal({
				domain = "CurrentPaneDomain",
			}),
		},
		{
			key = "s",
			mods = "CMD|SHIFT",
			action = act.SplitVertical({
				domain = "CurrentPaneDomain",
			}),
		},
		{
			key = "k",
			mods = "CMD",
			action = wezterm.action_callback(function(win, pane)
				if is_vim(pane) then
					win.perform_action(act.SendKey({ key = "k", mods = "CMD" }, pane))
				else
					win:perform_action(act.ClearScrollback("ScrollbackAndViewport"), pane)
				end
			end),
		},
		{
			key = "p",
			mods = "CMD|SHIFT",
			action = act.ActivateCommandPalette,
		},
		{
			key = "y",
			mods = "CMD",
			action = act.ActivateCopyMode,
		},
		{
			key = "r",
			mods = "CMD",
			action = act.ReloadConfiguration,
		},
		{
			key = "w",
			mods = "CMD",
			action = act.CloseCurrentPane({
				confirm = false,
			}),
		},
		{
			key = "c",
			mods = "CMD",
			action = act.CopyTo("Clipboard"),
		},
		{
			key = "v",
			mods = "CMD",
			action = act.PasteFrom("Clipboard"),
		},
		{
			key = "p",
			mods = "CMD",
			action = act.PasteFrom("Clipboard"),
		},
		{
			key = "m",
			mods = "CMD",
			action = act.Hide,
		},
		{
			key = "n",
			mods = "CMD",
			action = act.SpawnWindow,
		},
		{
			key = "t",
			mods = "CMD",
			action = act.SpawnTab("CurrentPaneDomain"),
		},
		{
			key = "f",
			mods = "CMD",
			action = act.Search("CurrentSelectionOrEmptyString"),
		},
		{
			key = "h",
			mods = "CMD",
			action = act.HideApplication,
		},
		{
			key = "q",
			mods = "CMD",
			action = act.QuitApplication,
		},
		{
			key = "1",
			mods = "CMD",
			action = act.ActivateTab(0),
		},
		{
			key = "2",
			mods = "CMD",
			action = act.ActivateTab(1),
		},
		{
			key = "3",
			mods = "CMD",
			action = act.ActivateTab(2),
		},
		{
			key = "4",
			mods = "CMD",
			action = act.ActivateTab(3),
		},
		{
			key = "5",
			mods = "CMD",
			action = act.ActivateTab(4),
		},
		{
			key = "6",
			mods = "CMD",
			action = act.ActivateTab(5),
		},
		{
			key = "7",
			mods = "CMD",
			action = act.ActivateTab(6),
		},
		{
			key = "8",
			mods = "CMD",
			action = act.ActivateTab(7),
		},
		{
			key = "9",
			mods = "CMD",
			action = act.ActivateTab(-1),
		},
		{
			key = "{",
			mods = "CMD|SHIFT",
			action = act.ActivateTabRelative(-1),
		},
		{
			key = "}",
			mods = "CMD|SHIFT",
			action = act.ActivateTabRelative(1),
		},
		{
			key = "-",
			mods = "CMD",
			action = act.DecreaseFontSize,
		},
		{
			key = "=",
			mods = "CMD",
			action = act.IncreaseFontSize,
		},
		{
			key = "0",
			mods = "CMD",
			action = act.ResetFontSize,
		},
		{
			key = "LeftArrow",
			mods = "CMD|SHIFT",
			action = act.ActivatePaneDirection("Left"),
		},
		{
			key = "RightArrow",
			mods = "CMD|SHIFT",
			action = act.ActivatePaneDirection("Right"),
		},
		{
			key = "UpArrow",
			mods = "CMD|SHIFT",
			action = act.ActivatePaneDirection("Up"),
		},
		{
			key = "DownArrow",
			mods = "CMD|SHIFT",
			action = act.ActivatePaneDirection("Down"),
		},
	}
end

local function setup_key_tables()
	return {
		copy_mode = {},

		search_mode = {
			{
				key = "Enter",
				mods = "NONE",
				action = act.CopyMode("PriorMatch"),
			},
			{
				key = "Escape",
				mods = "NONE",
				action = act.CopyMode("Close"),
			},
			{
				key = "n",
				mods = "CMD",
				action = act.CopyMode("NextMatch"),
			},
			{
				key = "p",
				mods = "CMD",
				action = act.CopyMode("PriorMatch"),
			},
			{
				key = "r",
				mods = "CMD",
				action = act.CopyMode("CycleMatchType"),
			},
			{
				key = "u",
				mods = "CMD",
				action = act.CopyMode("ClearPattern"),
			},
			{
				key = "PageUp",
				mods = "NONE",
				action = act.CopyMode("PriorMatchPage"),
			},
			{
				key = "PageDown",
				mods = "NONE",
				action = act.CopyMode("NextMatchPage"),
			},
			{
				key = "UpArrow",
				mods = "NONE",
				action = act.CopyMode("PriorMatch"),
			},
			{
				key = "DownArrow",
				mods = "NONE",
				action = act.CopyMode("NextMatch"),
			},
		},
	}
end

config = setup_shell(config)
config = setup_window(config)
config = setup_font(config)
config = setup_cursor_and_tabs(config)
config.disable_default_key_bindings = true

local base_keys = setup_base_keybindings()
local smart_splits_keys = generate_smart_splits_keys()

config.keys = base_keys
for _, key_binding in ipairs(smart_splits_keys) do
	table.insert(config.keys, key_binding)
end

config.key_tables = setup_key_tables()

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

return config
