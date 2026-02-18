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
    -- SSH domains for remote hosts. nostromo is the local Lima VM (lima-default).
    -- Other hosts require tailnet connection.
    ssh_domains = {
      {
        name = "nostromo",
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
        name = "forum",
        remote_address = "forum",
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
