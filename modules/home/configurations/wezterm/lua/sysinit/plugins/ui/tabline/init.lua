local wezterm = require("wezterm")
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
local theme_config = require("sysinit.theme_config")
local M = {}

function M.setup(config)
	-- Setup tabline first before applying to config
	tabline.setup({
		options = {
			theme = theme_config.colorscheme == "solarized" and {
				normal_mode = {
					a = { fg = theme_config.palette.base03, bg = theme_config.palette.blue },
					b = { fg = theme_config.palette.blue, bg = theme_config.palette.base02 },
					c = { fg = theme_config.palette.base0, bg = theme_config.palette.base03 },
				},
				copy_mode = {
					a = { fg = theme_config.palette.base03, bg = theme_config.palette.yellow },
					b = { fg = theme_config.palette.yellow, bg = theme_config.palette.base02 },
					c = { fg = theme_config.palette.base0, bg = theme_config.palette.base03 },
				},
				search_mode = {
					a = { fg = theme_config.palette.base03, bg = theme_config.palette.green },
					b = { fg = theme_config.palette.green, bg = theme_config.palette.base02 },
					c = { fg = theme_config.palette.base0, bg = theme_config.palette.base03 },
				},
				tab = {
					active = { fg = theme_config.palette.blue, bg = theme_config.palette.base02 },
					inactive = { fg = theme_config.palette.base0, bg = theme_config.palette.base03 },
					inactive_hover = { fg = theme_config.palette.cyan, bg = theme_config.palette.base02 },
				}
			} or config.colors,
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
end

return M
