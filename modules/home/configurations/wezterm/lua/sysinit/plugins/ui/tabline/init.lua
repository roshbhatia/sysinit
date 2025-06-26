local wezterm = require("wezterm")
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
local M = {}

function M.setup()
	tabline.setup({
		options = {
			theme = "Catppuccin Frappe",
			section_separators = {
				left = wezterm.nerdfonts.ple_right_half_circle_thick,
				right = wezterm.nerdfonts.ple_left_half_circle_thick,
			},
			component_separators = {
				left = wezterm.nerdfonts.ple_right_half_cirle_thin,
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
					padding = {
						left = 1,
						right = 1,
					},
				},
				"/",
				{
					"process",
					padding = {
						left = 1,
						right = 2,
					},
				},
				{
					"zoomed",
					padding = {
						left = 1,
						right = 1,
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
			tabline_x = {},
			tabline_y = {},
			tabline_z = {
				"window",
			},
		},
		extensions = {},
	})
end

return M

