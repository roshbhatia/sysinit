local wezterm = require("wezterm")
local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")
local M = {}

local function is_vim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

local function get_vim_mode(pane)
	local mode = pane:get_user_vars().ZVM_MODE or ""
	local mode_map = {
		i = "INSERT",
		v = "VISUAL",
		n = "NORMAL",
	}
	return mode_map[mode] or mode
end

local function get_bar_config()
	return {
		padding = {
			left = 3,
			right = 3,
			tabs = {
				left = 0,
				right = 2,
			},
		},
		modules = {
			hostname = {
				enabled = false,
			},
			workspace = {
				enabled = false,
			},
			leader = {
				enabled = false,
			},
			clock = {
				enabled = false,
			},
			username = {
				enabled = false,
			},
			vim_mode = {
				enabled = true,
				icon = "󰕷",
				format = function(mode)
					return string.format(" %s ", mode or "")
				end,
			},
		},
	}
end

local function setup_tab_bar_visibility()
	wezterm.on("update-status", function(window, pane)
		local tab_bar_hidden = is_vim(pane)
		local overrides = window:get_config_overrides() or {}

		if tab_bar_hidden ~= (overrides.enable_tab_bar == false) then
			overrides.enable_tab_bar = not tab_bar_hidden
			window:set_config_overrides(overrides)
		end

		if not tab_bar_hidden then
			local vim_mode = get_vim_mode(pane)
			if vim_mode and vim_mode ~= "" then
				window:set_right_status(string.format("󰕷 %s ", vim_mode))
			else
				window:set_right_status("")
			end
		end
	end)
end

function M.setup(config)
	local bar_config = get_bar_config()
	bar.apply_to_config(config, bar_config)

	setup_tab_bar_visibility()

	return config
end

return M
