local wezterm = require("wezterm")
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
local theme_config = require("sysinit.theme_config")
local M = {}

function M.setup(config)
	tabline.setup({
		options = {
			theme = config.colors,
			section_separators = "",
			component_separators = "",
			tab_separators = "",
		},
		sections = {
			tabline_a = {
				"mode",
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
				"workspace",
			},
			tabline_z = {
				" 󱄅 ",
			},
		},
		extensions = {},
	})

	tabline.apply_to_config(config)
	tabline.set_theme(theme_config.theme_name)
end

return M

