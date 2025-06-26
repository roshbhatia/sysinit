local wezterm = require("wezterm")
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
local M = {}

function M.setup(config)
	tabline.setup({
		options = {
			icons_enabled = false,
			theme = "Catppuccin Frappe",
			section_separators = {
				left = wezterm.nerdfonts.md_solid,
				right = wezterm.nerdfonts.md_solid,
			},
			tab_separators = {
				left = " ",
				right = "",
			},
		},
		sections = {
			tabline_a = {
				"mode",
			},
			tabline_b = {
				"workspace",
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

	return config
end

return M

