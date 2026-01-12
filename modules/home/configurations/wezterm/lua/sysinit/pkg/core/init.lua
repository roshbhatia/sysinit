local M = {}

local username = os.getenv("USER") or ""
local nix_bin = "/etc/profiles/per-user/" .. username .. "/bin"

local function get_basic_config()
  return {
    pane_focus_follows_mouse = false,
    -- We use a nix-installed zsh as the default shell.
    -- On darwin there's a /bin/zsh that we choose to not mess with
    default_prog = {
      nix_bin .. "/zsh",
    },
    -- Will only work when connected to the tailnet.
    -- As such, can safely ignore this when we're on the work machine.
    -- I'm fine hardcoding the list of systems here for now.
    ssh_domains = {
      {
        name = "arrakis",
        remote_address = "arrakis",
        username = username,
      },
      {
        name = "varre",
        remote_address = "varre",
        username = username,
      },
      {
        name = "lv426",
        remote_address = "lv426",
        username = username,
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
