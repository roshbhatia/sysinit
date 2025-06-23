local sessionizer = wezterm.plugin.require("https://github.com/mikkasendke/sessionizer.wezterm")
local M = {}

local function create_schema()
	return {
		options = {
			prompt = " Select workspace 󰄾 ",
		},
		sessionizer.DefaultWorkspace({}),
		sessionizer.FdSearch("~/github"),
	}
end

local function get_workspace_keys()
	local schema = create_schema()

	return {
		{
			key = "s",
			mods = "CMD",
			action = sessionizer.show(schema),
		},
	}
end

function M.setup(config)
	local workspace_keys = get_workspace_keys()
	for _, key_binding in ipairs(workspace_keys) do
		table.insert(config.keys, key_binding)
	end
	return config
end

return M

