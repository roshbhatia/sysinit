local M = {}

local username = os.getenv("USER") or ""
local home = os.getenv("HOME") or ""
local xdg_config_home = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")

local nix_bin = "/etc/profiles/per-user/" .. username .. "/bin"
local nushell_config_dir = xdg_config_home .. "/nushell"

local function get_basic_config()
  return {
    set_environment_variables = {
      TERM = "wezterm",
      -- PATH is managed by Nu shell environment - inherit from parent
      XDG_CONFIG_HOME = xdg_config_home,
    },
    automatically_reload_config = true,
    pane_focus_follows_mouse = true,
    status_update_interval = 25,
    default_prog = {
      nix_bin .. "/nu",
      "--config",
      nushell_config_dir .. "/config.nu",
      "--env-config",
      nushell_config_dir .. "/env.nu",
      "--include-path",
      nushell_config_dir,
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
