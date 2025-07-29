local M = {}

local username = os.getenv("USER")
local home = (os.getenv("HOME") or "/home/") .. (username or "user")
local nix_bin = "/etc/profiles/per-user/" .. username .. "/bin"

local function get_basic_config()
	return {
		set_environment_variables = {
			TERM = "wezterm",
			PATH = os.getenv("PATH") .. ":" .. nix_bin,
			XDG_CONFIG_HOME = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config"),
			XDG_DATA_HOME = os.getenv("XDG_DATA_HOME") or (home .. "/.local/share"),
			XDG_CACHE_HOME = os.getenv("XDG_CACHE_HOME") or (home .. "/.cache"),
		},
		automatically_reload_config = true,
		pane_focus_follows_mouse = true,
		status_update_interval = 25,
		default_prog = {
			"nu",
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

