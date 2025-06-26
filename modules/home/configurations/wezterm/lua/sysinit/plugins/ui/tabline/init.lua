local wezterm = require("wezterm")
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
local M = {}

function M.setup(theme)
	tabline.setup({
		options = {
			theme = theme,
			section_separators = {
				left = wezterm.nerdfonts.ple_right_half_circle_thick,
				right = wezterm.nerdfonts.ple_left_half_circle_thick,
			},
			component_separators = {
				left = wezterm.nerdfonts.ple_right_half_circle_thin,
				right = wezterm.nerdfonts.ple_left_half_circle_thin,
			},
			tab_separators = {
				left = wezterm.nerdfonts.ple_right_half_circle_thick,
				right = wezterm.nerdfonts.ple_left_half_circle_thick,
			},
		},
		sections = {
			tabline_a = {
				"mode",
			},
			tabline_b = {
				" ",
			},
			tabline_c = {
				" ",
			},
			tab_active = {
				"index",
				{
					"parent",
					padding = 0,
				},
				"/",
				{
					"cwd",
					padding = {
						left = 0,
						right = 1,
					},
				},
				{
					"zoomed",
					padding = 0,
				},
			},
			tab_inactive = {
				"index",
				{
					"process",
					padding = {
						left = 0,
						right = 1,
					},
				},
			},
			tabline_x = {},
			tabline_y = {},
			tabline_z = {
				"domain",
			},
		},
		extensions = {},
	})
end

return M

