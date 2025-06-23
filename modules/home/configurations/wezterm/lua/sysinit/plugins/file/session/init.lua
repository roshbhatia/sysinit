local wezterm = require("wezterm")
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local M = {}

local colors = {
	green = "#A6E3A1", -- For ~/github/personal/roshbhatia
	red = "#F38BA8", -- For ~/github/personal (excluding roshbhatia)
	blue = "#89B4FA", -- For ~/github/work
	default = "#FFFFFF", -- Fallback
}

workspace_switcher.workspace_formatter = function(label)
	local emoji = "󱂬 "
	local path = label or ""

	local color = colors.default

	if path:find("^~/github/personal/roshbhatia") then
		color = colors.green
		emoji = " "
	elseif path:find("^~/github/personal") then
		color = colors.red
		emoji = " "
	elseif path:find("^~/github/work") then
		color = colors.blue
		emoji = " "
	end

	return wezterm.format({
		{
			Foreground = {
				Color = color,
			},
		},
		{
			Text = emoji .. label,
		},
	})
end

local function get_workspace_keys()
	return {
		{
			key = "s",
			mods = "CMD",
			action = workspace_switcher.switch_workspace({
				extra_args = " | rg -Fxf ~/github",
			}),
		},
		{
			key = "S",
			mods = "CMD",
			action = workspace_switcher.switch_to_prev_workspace(),
		},
	}
end

function M.setup(config)
	workspace_switcher.apply_to_config(config)

	local workspace_keys = get_workspace_keys()
	for _, key_binding in ipairs(workspace_keys) do
		table.insert(config.keys, key_binding)
	end

	return config
end

return M

