local wezterm = require("wezterm")
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
local M = {}

local function is_vim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

function M.setup(config)
	tabline.setup({
		options = {
			icons_enabled = true,
			theme = "Catppuccin Frappe",
			tabs_enabled = true,
			theme_overrides = {},
			section_separators = {
				left = wezterm.nerdfonts.pl_left_hard_divider,
				right = wezterm.nerdfonts.pl_right_hard_divider,
			},
			component_separators = {
				left = wezterm.nerdfonts.pl_left_soft_divider,
				right = wezterm.nerdfonts.pl_right_soft_divider,
			},
			tab_separators = {
				left = wezterm.nerdfonts.pl_left_hard_divider,
				right = wezterm.nerdfonts.pl_right_hard_divider,
			},
		},
		sections = {
			tabline_a = { "mode" },
			tabline_b = { "workspace" },
			tabline_c = { " " },
			tab_active = {
				"index",
				{ "parent", padding = 0 },
				"/",
				{ "cwd", padding = { left = 0, right = 1 } },
				{ "zoomed", padding = 0 },
			},
			tab_inactive = { "index", { "process", padding = { left = 0, right = 1 } } },
			tabline_x = {},
			tabline_y = {},
			tabline_z = { "domain" },
		},
		extensions = {},
	})

	return config
end

return M

