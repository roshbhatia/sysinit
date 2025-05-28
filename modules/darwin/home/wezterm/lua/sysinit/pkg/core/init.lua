local M = {}

local function get_basic_config()
	return {
		set_environment_variables = {
			TERM = "wezterm",
		},
		automatically_reload_config = true,
		pane_focus_follows_mouse = true,
	}
end

function M.setup(config)
	local basic_config = get_basic_config()
	for key, value in pairs(basic_config) do
		config[key] = value
	end

	return config
end

return M
