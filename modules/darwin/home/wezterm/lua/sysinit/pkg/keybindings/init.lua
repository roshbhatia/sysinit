local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

-- Check if a pane is running Neovim
local function is_vim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

-- Direction mappings
local direction_keys = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

-- Split navigation function
local function split_nav(resize_or_move, key)
	return {
		key = key,
		mods = resize_or_move == "resize" and "META" or "CTRL",
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				-- Pass the keys through to Neovim
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

local function theme_switcher(window, pane)
	local schemes = wezterm.get_builtin_color_schemes()
	local choices = {}
	local username = os.getenv("USER")
	local theme_file = "/Users/" .. username .. "/.cache/wezterm/theme"

	for key, _ in pairs(schemes) do
		table.insert(choices, { label = tostring(key) })
	end

	table.sort(choices, function(c1, c2)
		return c1.label < c2.label
	end)

	window:perform_action(
		act.InputSelector({
			title = "Theme Picker",
			choices = choices,
			fuzzy = true,

			action = wezterm.action_callback(function(inner_window, inner_pane, _, label)
				local file = io.open(theme_file, "w")
				if file then
					file:write(label)
					file:close()

					inner_window:toast_notification("WezTerm", "Theme changed to " .. label, nil, 4000)
					inner_window:perform_action(act.ReloadConfiguration, inner_pane)
				else
					inner_window:toast_notification("WezTerm", "Failed to update theme file", nil, 4000)
				end
			end),
		}),
		pane
	)
end

function M.setup(config)
	-- Smart splits keybindings
	local smart_splits_keys = { -- Move between split panes
		split_nav("move", "h"),
		split_nav("move", "j"),
		split_nav("move", "k"),
		split_nav("move", "l"), -- Resize panes
		split_nav("resize", "h"),
		split_nav("resize", "j"),
		split_nav("resize", "k"),
		split_nav("resize", "l"),
	}

	-- Base keybindings
	local base_keys = { -- Split creation
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
		}, -- Common actions
		{
			key = "k",
			mods = "CMD",
			action = wezterm.action_callback(function(win, pane)
				if not is_vim(pane) then
					-- Only clear scrollback if NOT in vim
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
		}, -- Standard Mac keybindings
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
		}, -- Tab navigation
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
		}, -- Font size
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
		}, -- Alternative pane navigation
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
		{
			key = "t",
			mods = "CTRL|SHIFT",
			action = wezterm.action_callback(function(window, pane)
				theme_switcher(window, pane)
			end),
		},
	}

	-- Combine base keys with smart splits keys
	config.keys = base_keys
	for _, key_binding in ipairs(smart_splits_keys) do
		table.insert(config.keys, key_binding)
	end

	-- Key tables for special modes
	config.key_tables = {
		-- Empty copy mode (disabled)
		copy_mode = {},

		-- Search mode keys
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

	return config
end

return M

