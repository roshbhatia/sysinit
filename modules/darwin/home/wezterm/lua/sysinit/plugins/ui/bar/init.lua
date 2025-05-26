local wezterm = require("wezterm")
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
local M = {}

function M.setup(config)
	tabline.setup({
		options = {
			theme = "Rosé Pine (Gogh)",
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
	tabline.apply_to_config(config)
end

return M

