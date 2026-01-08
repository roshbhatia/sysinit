local M = {}

local username = os.getenv("USER") or ""
local nix_bin = "/etc/profiles/per-user/" .. username .. "/bin"
local json_loader = require("sysinit.pkg.utils.json_loader")

local function get_basic_config()
  -- Load shared PATH configuration from Nix-generated config.json
  local config_data = json_loader.load_json_file(json_loader.get_config_path("config.json"))
  local configured_path = table.concat(config_data.paths or {}, ":")

  -- Fallback to basic PATH if config doesn't have paths
  local current_path = os.getenv("PATH") or ""
  local final_path = configured_path ~= "" and configured_path or (nix_bin .. ":" .. current_path)

  return {
    enable_kitty_keyboard = true,
    pane_focus_follows_mouse = false,
    -- On darwin there's a /bin/zsh and /bin/bash that we choose to not mess with
    default_prog = {
      nix_bin .. "/zsh",
      -- "-c",
      -- nix_bin .. "/nu",
      -- "-l",
    },
    set_environment_variables = {
      PATH = final_path,
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
