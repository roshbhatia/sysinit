local utils = require("sysinit.pkg.utils")

local M = {}

local function get_basic_config()
  return {
    status_update_interval = 200,
    default_prog = {
      utils.get_nix_binary("zsh"),
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
