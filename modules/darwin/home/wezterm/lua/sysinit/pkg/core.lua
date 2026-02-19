local wezterm = require("wezterm")
local utils = require("sysinit.pkg.utils")

local M = {}

local function get_basic_config()
  local ssh_domains = wezterm.default_ssh_domains()
  
  -- Assume all remote hosts are POSIX shells for proper CWD handling
  for _, domain in ipairs(ssh_domains) do
    domain.assume_shell = "Posix"
  end

  return {
    status_update_interval = 100,
    default_prog = {
      utils.get_nix_binary("zsh"),
      "--login",
    },
    -- Auto-populate SSH domains from ~/.ssh/config (includes Lima VMs)
    -- Creates both SSH: and SSHMUX: prefixed domains for each host
    ssh_domains = ssh_domains,
  }
end

function M.setup(config)
  local basic_config = get_basic_config()

  for key, value in pairs(basic_config) do
    config[key] = value
  end
end

return M
