local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

local function is_vim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

local direction_keys = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

local function split_nav(resize_or_move, key, mods)
	return {
		key = key,
		mods = mods,
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				win:perform_action({
					SendKey = { key = key, mods = mods },
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

local function get_smart_splits()
	return {
		split_nav("move", "h", "CTRL"),
		split_nav("move", "j", "CTRL"),
		split_nav("move", "k", "CTRL"),
		split_nav("move", "l", "CTRL"),
		split_nav("resize", "h", "CTRL|SHIFT"),
		split_nav("resize", "j", "CTRL|SHIFT"),
		split_nav("resize", "k", "CTRL|SHIFT"),
		split_nav("resize", "l", "CTRL|SHIFT"),
	}
end

local function get_pane_keys()
	return {
		{
			key = "v",
			mods = "CTRL",
			action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
		},
		{
			key = "s",
			mods = "CTRL",
			action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
		},
		{
			key = "w",
			mods = "CMD",
			action = act.CloseCurrentPane({ confirm = false }),
		},
	}
end

local function get_clear_keys()
	return {
		{
			key = "k",
			mods = "CMD",
			action = wezterm.action_callback(function(win, pane)
				if is_vim(pane) then
					win:perform_action({
						SendKey = { key = "k", mods = "CMD" },
					}, pane)
				else
					win:perform_action(act.ClearScrollback("ScrollbackAndViewport"), pane)
				end
			end),
		},
		{
			key = "l",
			mods = "CTRL",
			action = wezterm.action_callback(function(win, pane)
				if is_vim(pane) then
					win:perform_action({
						SendKey = { key = "l", mods = "CTRL" },
					}, pane)
				else
					win:perform_action(act.ClearScrollback("ScrollbackAndViewport"), pane)
				end
			end),
		},
	}
end

local function get_scroll_keys()
	return {
		{
			key = "u",
			mods = "CTRL",
			action = wezterm.action_callback(function(win, pane)
				if is_vim(pane) then
					win:perform_action({
						SendKey = { key = "u", mods = "CTRL" },
					}, pane)
				else
					win:perform_action(act.ScrollByLine(-40))
				end
			end),
		},
		{
			key = "d",
			mods = "CTRL",
			action = wezterm.action_callback(function(win, pane)
				if is_vim(pane) then
					win:perform_action({
						SendKey = { key = "d", mods = "CTRL" },
					}, pane)
				else
					win:perform_action(act.ScrollByLine(40))
				end
			end),
		},
	}
end

local function get_clipboard_keys()
	return {
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
	}
end

local function get_window_keys()
	return {
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
	}
end

local function get_tab_keys()
	return {
		{
			key = "t",
			mods = "CMD",
			action = act.SpawnTab("CurrentPaneDomain"),
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
	}
end

local function get_search_keys()
	return {
		{
			key = "f",
			mods = "CMD",
			action = act.Search("CurrentSelectionOrEmptyString"),
		},
	}
end

local function get_font_keys()
	return {
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
	}
end

local function get_key_tables()
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

function M.setup(config)
	local all_keys = {}

	local key_groups = {
		get_smart_splits(),
		get_pane_keys(),
		get_clear_keys(),
		get_scroll_keys(),
		get_clipboard_keys(),
		get_window_keys(),
		get_tab_keys(),
		get_search_keys(),
		get_font_keys(),
	}

	for _, group in ipairs(key_groups) do
		for _, key_binding in ipairs(group) do
			table.insert(all_keys, key_binding)
		end
	end

	config.keys = all_keys
	config.key_tables = get_key_tables()

	return config
end

return M
