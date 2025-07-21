local wezterm = require("wezterm")
local theme_config = require("sysinit.theme_config")
local M = {}

local function get_window_appearance_config()
	local opacity = theme_config.transparency.enable and theme_config.transparency.opacity or 1.0
	local blur = theme_config.transparency.enable and 80 or 0

	return {
		window_background_opacity = opacity,
		macos_window_background_blur = blur,
	}
end

function M.setup(config)
	local configs = {
		get_window_appearance_config(),
	}

	for _, cfg in ipairs(configs) do
		for key, value in pairs(cfg) do
			config[key] = value
		end
	end
end

return M
