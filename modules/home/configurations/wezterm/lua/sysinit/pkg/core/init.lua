---@diagnostic disable: ambiguity-1
local M = {}

local username = os.getenv("USER")
local home = os.getenv("HOME") or "/home/" .. username

local nix_bin = "/etc/profiles/per-user/" .. username .. "/bin/"

local function get_basic_config()
	return {
		set_environment_variables = {
			TERM = "wezterm",
		},
		automatically_reload_config = true,
		pane_focus_follows_mouse = true,
		status_update_interval = 25,
		default_prog = {
			nix_bin .. "nu",
			"--config",
			home .. "/.config/nushell/config.nu",
			"--env-config",
			home .. "/.config/nushell/env.nu",
		},
	}
end

function M.setup(config)
	local basic_config = get_basic_config()
	for key, value in pairs(basic_config) do
		config[key] = value
	end
end

return M

