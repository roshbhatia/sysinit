local M = {}
local home = os.getenv("HOME") or ""
local xdg_config_home = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")

local function get_basic_config()
  local username = os.getenv("USER") or ""
  local nix_bin = "/etc/profiles/per-user/" .. username .. "/bin"

  local shells = {
    zsh = { nix_bin .. "/zsh" },
  }

  return {
    set_environment_variables = {
      TERM = "wezterm",
      XDG_CONFIG_HOME = xdg_config_home,
    },
    automatically_reload_config = true,
    pane_focus_follows_mouse = false,
    status_update_interval = 20,
    default_prog = shells.zsh,
  }
end

function M.setup(config)
  local basic_config = get_basic_config()

  for key, value in pairs(basic_config) do
    config[key] = value
  end
end

return M
