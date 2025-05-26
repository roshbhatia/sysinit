local wezterm = require("wezterm")
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local M = {}

function M.setup(config)
	workspace_switcher.apply_to_config(config)

	local workspace_switcher_keys = {
		{
			key = "s",
			mods = "CMD",
			action = workspace_switcher.switch_workspace(),
		},
		{
			key = "S",
			mods = "CMD",
			action = workspace_switcher.switch_to_prev_workspace(),
		},
	}

	for _, key_binding in ipairs(workspace_switcher_keys) do
		table.insert(config.keys, key_binding)
	end
end

return M

