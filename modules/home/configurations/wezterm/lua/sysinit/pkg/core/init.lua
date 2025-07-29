local M = {}

local username = os.getenv("USER")
local home = os.getenv("HOME")

local nix_bin = "/etc/profiles/per-user/" .. username .. "/bin/"
local nushell_config_dir = home .. "/.config/nushell"

local function get_basic_config()
	local path_components = {
		"/etc/profiles/per-user/" .. username .. "/bin",
		"/opt/homebrew/bin",
		"/opt/homebrew/sbin",
		"/usr/bin",
		"/usr/sbin",
		home .. "/.cargo/bin",
		home .. "/.local/bin",
		home .. "/.npm-global/bin",
		home .. "/.uv/bin",
		home .. "/.yarn/bin",
		home .. "/bin",
		home .. "/go/bin",
	}
	
	local path = table.concat(path_components, ":")
	
	return {
		set_environment_variables = {
			TERM = "wezterm",
			PATH = path,
		},
		automatically_reload_config = true,
		pane_focus_follows_mouse = true,
		status_update_interval = 25,
		default_prog = {
			nix_bin .. "nu",
			"--config",
			nushell_config_dir .. "/config.nu",
			"--env-config",
			nushell_config_dir .. "/env.nu",
			"--include-path",
			nushell_config_dir,
			"--login",
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
