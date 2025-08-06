local M = {}

local wezterm = require("wezterm")
local json_loader = require("sysinit.pkg.utils.json_loader")
local core_config = json_loader.load_json_file(json_loader.get_config_path("core_config.json"))

local home = os.getenv("HOME") or ""
local xdg_config_home = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")

local function get_basic_config(config_data)
  local username = os.getenv("USER") or ""
  local nix_bin = "/etc/profiles/per-user/" .. username .. "/bin"
  local nushell_config_dir = xdg_config_home .. "/nushell"

  local shells = {
    zsh = { nix_bin .. "/zsh" },
    nu = {
      nix_bin .. "/nu",
      "--config",
      nushell_config_dir .. "/config.nu",
      "--env-config",
      nushell_config_dir .. "/env.nu",
      "--include-path",
      nushell_config_dir,
    },
  }

  local wezterm_entrypoint = core_config.wezterm_entrypoint or "zsh"

  return {
    set_environment_variables = {
      TERM = "wezterm",
      XDG_CONFIG_HOME = xdg_config_home,
    },
    automatically_reload_config = true,
    pane_focus_follows_mouse = true,
    status_update_interval = 25,
    default_prog = shells[wezterm_entrypoint] or shells.zsh,
  }
end

function M.setup(config)
  local basic_config = get_basic_config(core_config)

  for key, value in pairs(basic_config) do
    config[key] = value
  end
end

return M

