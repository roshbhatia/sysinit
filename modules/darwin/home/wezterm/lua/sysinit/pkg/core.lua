local wezterm = require("wezterm")
local utils = require("sysinit.pkg.utils")

local M = {}

local function get_basic_config()
  local ssh_domains = {
    {
      name = "vorgossos",
      remote_address = "vorgossos.stork-eel.ts.net",
      username = "rshnbhatia",
      assume_shell = "Posix",
    },
    {
      name = "huey",
      remote_address = "huey.taila415c.ts.net",
      username = "rosh",
      assume_shell = "Posix",
    },
  }

  local env_data = utils.load_json_file(utils.get_config_path("env.json"))

  return {
    ssh_domains = ssh_domains,
    set_environment_variables = {
      PATH = env_data.PATH,
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
