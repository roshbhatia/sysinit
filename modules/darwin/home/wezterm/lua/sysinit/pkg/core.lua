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
    -- Cursor trail animation (smoother and snappier than default)
    cursor_trail = {
      enabled = true,
      -- Reduced dwell time for quicker response
      dwell_threshold = 50,
      -- Increased distance for less frequent but more noticeable trails
      distance_threshold = 6,
      -- Shorter duration for snappier animation
      duration = 200,
      -- Reduced spread for tighter, smoother trail
      spread = 1.5,
      -- Slightly higher opacity for better visibility
      opacity = 0.7,
    },
    -- Higher FPS for smoother animations
    animation_fps = 60,
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
