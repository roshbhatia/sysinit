local wezterm = require("wezterm")
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
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

local function vim_mode_component(window)
	local pane = window:active_pane()
	if is_vim(pane) then
		local mode = get_vim_mode(pane)
		if mode and mode ~= "" then
			return mode
		end
	end
	return ""
end

local function setup_tab_bar_visibility()
	wezterm.on("update-status", function(window, pane)
		local tab_bar_hidden = is_vim(pane)
		local overrides = window:get_config_overrides() or {}
		if tab_bar_hidden ~= (overrides.enable_tab_bar == false) then
			overrides.enable_tab_bar = not tab_bar_hidden
			window:set_config_overrides(overrides)
		end
	end)
end

function M.setup(config)
	tabline.setup({
		options = {
			icons_enabled = false,
			theme = config.colors,
			tabs_enabled = true,
			section_separators = "",
			component_separators = "",
			tab_separators = "",
		},
		sections = {
			tabline_a = { vim_mode_component },
			tabline_b = {},
			tabline_c = {},
			tab_active = {
				{ "cwd", max_length = 20, padding = { left = 1, right = 1 } },
			},
			tab_inactive = {
				{ "cwd", max_length = 15, padding = { left = 1, right = 1 } },
			},
			tabline_x = {},
			tabline_y = {},
			tabline_z = {},
		},
	})

	tabline.apply_to_config(config)
	setup_tab_bar_visibility()
	return config
end

return M

