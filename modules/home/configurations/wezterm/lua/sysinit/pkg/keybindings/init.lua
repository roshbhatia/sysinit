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
			mods = "CTRL",
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
						SendKey = {
							key = "k",
							mods = "CMD",
						},
					}, pane)
				else
					win:perform_action(act.ClearScrollback("ScrollbackAndViewport"), pane)
				end
			end),
		},
		{
			key = "k",
			mods = "CTRL",
			action = wezterm.action_callback(function(win, pane)
				if is_vim(pane) then
					win:perform_action({
						SendKey = {
							key = "k",
							mods = "CTRL",
						},
					}, pane)
				else
					win:perform_action(act.ClearScrollback("ScrollbackAndViewport"), pane)
				end
			end),
		},
	}
end

local function get_pallete_keys()
	return {
		{
			key = "p",
			mods = "CTRL|SHIFT",
			action = act.ActivateCommandPalette,
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
						SendKey = {
							key = "u",
							mods = "CTRL",
						},
					}, pane)
				else
					win:perform_action(act.ScrollByLine(-40), pane)
				end
			end),
		},
		{
			key = "d",
			mods = "CTRL",
			action = wezterm.action_callback(function(win, pane)
				if is_vim(pane) then
					win:perform_action({
						SendKey = {
							key = "d",
							mods = "CTRL",
						},
					}, pane)
				else
					win:perform_action(act.ScrollByLine(40), pane)
				end
			end),
		},
	}
end

local function get_window_keys()
	return {
		{
			key = "n",
			mods = "CTRL",
			action = act.SpawnWindow,
		},
		{
			key = "t",
			mods = "CMD|SHIFT",
			action = wezterm.action_callback(function(window)
				local overrides = window:get_config_overrides() or {}
				if not overrides.window_background_opacity then
					overrides.window_background_opacity = 1
				elseif overrides.window_background_opacity == 1 then
					overrides.window_background_opacity = nil
				end
				window:set_config_overrides(overrides)
			end),
		},
	}
end

local function get_tab_keys()
	return {
		{
			key = "t",
			mods = "CTRL",
			action = act.SpawnTab("CurrentPaneDomain"),
		},
		{
			key = "1",
			mods = "CTRL",
			action = act.ActivateTab(0),
		},
		{
			key = "2",
			mods = "CTRL",
			action = act.ActivateTab(1),
		},
		{
			key = "3",
			mods = "CTRL",
			action = act.ActivateTab(2),
		},
		{
			key = "4",
			mods = "CTRL",
			action = act.ActivateTab(3),
		},
		{
			key = "5",
			mods = "CTRL",
			action = act.ActivateTab(4),
		},
		{
			key = "6",
			mods = "CTRL",
			action = act.ActivateTab(5),
		},
		{
			key = "7",
			mods = "CTRL",
			action = act.ActivateTab(6),
		},
		{
			key = "8",
			mods = "CTRL",
			action = act.ActivateTab(7),
		},
	}
end

local function get_search_keys()
	return {
		{
			key = "Escape",
			mods = "CTRL",
			action = act.ActivateCopyMode,
		},
		{
			key = "/",
			mods = "CTRL",
			action = act.Search("CurrentSelectionOrEmptyString"),
		},
	}
end

function M.setup(config)
	local all_keys = {}

	local key_groups = {
		get_smart_splits(),
		get_pane_keys(),
		get_clear_keys(),
		get_pallete_keys(),
		get_scroll_keys(),
		get_window_keys(),
		get_tab_keys(),
		get_search_keys(),
	}

	for _, group in ipairs(key_groups) do
		for _, key_binding in ipairs(group) do
			table.insert(all_keys, key_binding)
		end
	end

	config.keys = all_keys

	return config
end

return M

