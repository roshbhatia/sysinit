local wezterm = require("wezterm")
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
local M = {}

function M.setup(config)
	tabline.apply_to_config(config)
	tabline.setup({
		options = {
			icons_enabled = true,
			theme = "Catppuccin Mocha",
			section_separators = {
				left = wezterm.nerdfonts.pl_left_hard_divider,
				right = wezterm.nerdfonts.pl_right_hard_divider,
			},
			component_separators = {
				left = wezterm.nerdfonts.pl_left_soft_divider,
				right = wezterm.nerdfonts.pl_right_soft_divider,
			},
		},
		sections = {
			tabline_a = { "mode" },
			tabline_b = { "workspace" },
			tabline_c = {
				function()
					return os.getenv("ZVM_MODE") or ""
				end,
			},
			tabline_x = { "git_branch" },
		},
		extensions = { "smart_workspace_switcher" },
	})
end

return M
