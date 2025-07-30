local wezterm = require("wezterm")
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
local theme_config = require("sysinit.theme_config")
local M = {}

local function zvm_mode_component(pane)
	local mode = pane:get_user_vars().ZVM_MODE
	if not mode or mode == "" then
		return ""
	end
	local mode_map = {
		n = "NORMAL",
		i = "INSERT",
		v = "VISUAL",
		vl = "VISUAL LINE",
		r = "REPLACE",
	}
	local display = mode_map[mode] or mode
	return "<<" .. display .. ">>"
end

function M.setup(config)
	tabline.setup({
		options = {
			theme = theme_config.theme_name,
			section_separators = "",
			component_separators = "",
			tab_separators = "",
		},
		sections = {
			tabline_a = {
				"mode",
				zvm_mode_component,
			},
			tabline_b = {
				"hostname",
			},
			tabline_c = {
				" ",
			},
			tab_active = {
				"index",
				{
					"process",
					padding = {
						left = 1,
						right = 2,
					},
				},
			},
			tab_inactive = {
				"index",
				{
					"process",
					padding = {
						left = 1,
						right = 2,
					},
				},
			},
			tabline_x = {
				" ",
			},
			tabline_y = {
				"domain",
			},
			tabline_z = {
				" 󱄅  ",
			},
		},
		extensions = {},
	})

	tabline.apply_to_config(config)
	tabline.set_theme(theme_config.theme_name)
end

return M
