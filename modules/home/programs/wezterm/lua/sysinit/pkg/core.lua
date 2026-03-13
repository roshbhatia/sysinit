local wezterm = require("wezterm")
local utils = require("sysinit.pkg.utils")

local M = {}

local function get_basic_config()
  local env_data = utils.load_json_file(utils.get_config_path("env.json"))
  local nix_zsh = utils.get_nix_binary("zsh")

  return {
    default_prog = { nix_zsh, "-l" },
    set_environment_variables = {
      PATH = env_data.PATH,
      SHELL = nix_zsh,
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
