local M = {}

local username = os.getenv("USER") or ""
local nix_bin = "/etc/profiles/per-user/" .. username .. "/bin"

local function get_basic_config()
  return {
    pane_focus_follows_mouse = false,
    default_prog = {
      nix_bin .. "/nu",
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
