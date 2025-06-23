local wezterm = require("wezterm")
local sessionizer = wezterm.plugin.require("https://github.com/mikkasendke/sessionizer.wezterm")
local history = wezterm.plugin.require("https://github.com/mikkasendke/sessionizer-history.git")
local zoxide = wezterm.plugin.require("https://github.com/mikkasendke/sessionizer-zoxide.git")

local M = {}

local function create_schema()
	return {
		options = {
			prompt = " Select workspace >> ",
			callback = history.Wrapper(sessionizer.DefaultCallback),
		},

		history.MostRecentWorkspace({}),

		{
			sessionizer.AllActiveWorkspaces({ filter_current = false, filter_default = false }),
			processing = sessionizer.for_each_entry(function(entry)
				entry.label = wezterm.format({
					{ Text = "󱂬 : " .. entry.label },
				})
			end),
		},

		sessionizer.FdSearch(wezterm.home_dir .. "/github"),

		zoxide.Zoxide({}),

		processing = sessionizer.for_each_entry(function(entry)
			entry.label = entry.label:gsub(wezterm.home_dir, "~")
		end),
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
		{
			key = "S",
			mods = "CMD",
			action = history.switch_to_most_recent_workspace,
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

