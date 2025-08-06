local M = {}

local wezterm = require("wezterm")
local home = os.getenv("HOME") or ""
local xdg_config_home = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
local config_file_path = xdg_config_home .. "/wezterm/core_config.json"

local function read_config_from_file()
  local file = io.open(config_file_path, "r")
  if file then
    local content = file:read("*a")
    file:close()
    local success, parsed_data = pcall(wezterm.json.decode, content)
    if success and parsed_data then
      return parsed_data
    end
  end

  return {}
end

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

  local wezterm_entrypoint = config_data.wezterm_entrypoint or "zsh"

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
  local core_config = read_config_from_file()
  local basic_config = get_basic_config(core_config)

  for key, value in pairs(basic_config) do
    config[key] = value
  end
end

return M
