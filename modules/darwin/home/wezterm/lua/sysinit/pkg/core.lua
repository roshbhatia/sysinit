local utils = require("sysinit.pkg.utils")

local M = {}

local function get_basic_config()
  return {
    status_update_interval = 200,
    pane_focus_follows_mouse = false,
    default_prog = {
      utils.get_nix_binary("zsh"),
      "--login",
    },
    -- Will only work when connected to the tailnet.
    -- As such, can safely ignore this when we're on the work machine.
    -- I'm fine hardcoding the list of systems here for now.
    ssh_domains = {
      {
        name = "ascalon",
        remote_address = "lima-default",
        username = utils.get_username(),
        multiplexing = "None",
      },
      {
        name = "arrakis",
        remote_address = "arrakis",
        username = utils.get_username(),
      },
      {
        name = "vorgossos",
        remote_address = "vorgossos",
        username = utils.get_username(),
      },
      {
        name = "lv426",
        remote_address = "lv426",
        username = utils.get_username(),
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
