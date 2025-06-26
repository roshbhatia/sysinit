local wezterm = require("wezterm")
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local M = {}

local function get_workspace_keys()
	return {
		{
			key = "\\",
			mods = "CMD|SHIFT",
			action = workspace_switcher.switch_workspace(),
		},
	}
end

function M.setup(config)
	workspace_switcher.apply_to_config(config)

	local workspace_keys = get_workspace_keys()

	for _, key_binding in ipairs(workspace_keys) do
		table.insert(config.keys, key_binding)
	end
end

return M

