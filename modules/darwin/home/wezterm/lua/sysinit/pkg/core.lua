local wezterm = require("wezterm")
local utils = require("sysinit.pkg.utils")

local M = {}

local function get_lima_ssh_port()
  local home = os.getenv("HOME")
  local ssh_config_path = home .. "/.lima/default/ssh.config"
  local file = io.open(ssh_config_path, "r")
  
  if not file then
    return nil
  end
  
  for line in file:lines() do
    local port = line:match("^%s*Port%s+(%d+)")
    if port then
      file:close()
      return port
    end
  end
  
  file:close()
  return nil
end

local function get_basic_config()
  local ssh_domains = {}
  
  -- Add Lima VM domain if available
  local lima_port = get_lima_ssh_port()
  if lima_port then
    table.insert(ssh_domains, {
      name = "lima-default",
      remote_address = "127.0.0.1:" .. lima_port,
      username = os.getenv("USER"),
      assume_shell = "Posix",
    })
  end

  return {
    status_update_interval = 100,
    default_prog = {
      utils.get_nix_binary("zsh"),
      "--login",
    },
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
