local M = {}

local home = os.getenv("HOME") or ""
local username = os.getenv("USER") or ""
local xdg_config_home = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")

local nix_bin = "/etc/profiles/per-user/" .. username .. "/bin"

local function get_basic_config()
  return {
    set_environment_variables = {
      TERM = "wezterm",
      XDG_CONFIG_HOME = xdg_config_home,
    },
    automatically_reload_config = true,
    pane_focus_follows_mouse = false,
    status_update_interval = 20,
    default_prog = {
      nix_bin .. "/nu",
      "-l",
      "--stdin",
    },
    -- Will only work when connected to the tailnet.
    -- As such, can safely ignore this when we're on the work machine.
    -- I'm fine hardcoding the list of systems here for now.
    ssh_domains = {
      {
        name = "arrakis",
        remote_address = "arrakis",
        username = username,
      },
      {
        name = "varre",
        remote_address = "varre",
        username = username,
      },
      {
        name = "lv426",
        remote_address = "lv426",
        username = username,
      },
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
