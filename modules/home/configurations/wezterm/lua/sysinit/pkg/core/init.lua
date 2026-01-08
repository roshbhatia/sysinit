local M = {}

local username = os.getenv("USER") or ""
local nix_bin = "/etc/profiles/per-user/" .. username .. "/bin"

local function get_basic_config()
  local current_path = os.getenv("PATH") or ""
  local path_with_nix = nix_bin .. ":" .. current_path

  return {
    enable_kitty_keyboard = true,
    pane_focus_follows_mouse = false,
    -- On darwin there's a /bin/zsh and /bin/bash that we choose to not mess with
    default_prog = {
      "/bin/sh",
      "-c",
      nix_bin .. "/nu -l",
    },
    set_environment_variables = {
      PATH = path_with_nix,
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
