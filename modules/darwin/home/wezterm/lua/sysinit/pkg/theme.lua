local wezterm = require("wezterm")
local M = {}

local function get_theme()
	local theme_file = wezterm.home_dir .. "/.cache/wezterm-theme"
	local success, data = pcall(wezterm.read_file, theme_file)
	return success and data or "rose-pine"
end

function M.setup(config)
	config.color_scheme = get_theme()
end

return M
